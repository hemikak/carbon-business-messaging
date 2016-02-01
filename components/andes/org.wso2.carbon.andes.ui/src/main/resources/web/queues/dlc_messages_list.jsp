<%@page import="java.sql.Array" %>
<%@page import="org.wso2.carbon.andes.stub.admin.types.Queue" %>
<%@page import="org.apache.axis2.AxisFault" %>
<%@ page import="org.wso2.carbon.andes.ui.UIUtils" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ taglib prefix="carbon" uri="http://wso2.org/projects/carbon/taglibs/carbontags.jar" %>
<%@ page import="org.wso2.carbon.ui.CarbonUIMessage" %>
<%@ page import="org.wso2.carbon.andes.stub.AndesAdminServiceStub" %>
<%@ page import="org.wso2.carbon.andes.stub.AndesAdminServiceBrokerManagerAdminException" %>
<%@ page import="org.wso2.carbon.andes.stub.admin.types.Message" %>
<%@ page import="org.wso2.andes.configuration.enums.AndesConfiguration" %>
<%@ page import="org.wso2.andes.configuration.AndesConfigurationManager" %>
<%@ page import="javax.xml.bind.SchemaOutputResolver" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="org.wso2.andes.kernel.AndesConstants" %>
<%@ page import="org.wso2.andes.server.queue.DLCQueueUtils" %>
<%@ page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@ page import="org.owasp.encoder.Encode" %>
<script type="text/javascript" src="js/treecontrol.js"></script>
<fmt:bundle basename="org.wso2.carbon.andes.ui.i18n.Resources">
    <jsp:include page="resources-i18n-ajaxprocessor.jsp"/>
    <carbon:jsi18n resourceBundle="org.wso2.carbon.andes.ui.i18n.Resources" request="<%=request%>"/>

    <script type="text/javascript" src="../admin/js/breadcrumbs.js"></script>
    <script type="text/javascript" src="../admin/js/cookies.js"></script>
    <script type="text/javascript" src="../admin/js/main.js"></script>
    <link rel="stylesheet" href="styles/dsxmleditor.css"/>
    <script type="text/javascript">

        function toggleCheck(source) {

            var allcheckBoxes = document.getElementsByName("checkbox");
            for (var i = 0; i < allcheckBoxes.length; i++) {
                if (allcheckBoxes[i].type == 'checkbox') {
                    allcheckBoxes[i].checked = source.checked;
                }
            }
        }

        function checkSelectAll(source) {
            var selectAllCheckBox = document.getElementsByName("selectAllCheckBox");
            if (selectAllCheckBox[0].checked) {
                selectAllCheckBox[0].checked = source.checked;
            }

            var allcheckBoxesInPage = $("input:checkbox");

            var totalCheckboxCount = allcheckBoxesInPage.size() - 1; ////removing the select all check box from the count.

            var checkedBoxes = $("input[@type=checkbox]:checked"); //the checked box count
            var checkedBoxesCount = checkedBoxes.size();

            if (totalCheckboxCount == checkedBoxesCount) {
                selectAllCheckBox[0].checked = true;
            }
        }

        function filterByQueue() {
            var filterQueueText = $("#queueName").val();
            if (filterQueueText == "") {
                $("#filterQueueName").val('<%=Encode.forJavaScript(request.getParameter("nameOfQueue"))%>');
            } else {
                $("#filterQueueName").val(filterQueueText);
            }
            document.getElementById('dummyForm').submit();
        }

        $(document).ready(function () {
            removeFirstAndLastPaginations();

        })
    </script>

    <%
        AndesAdminServiceStub stub = UIUtils.getAndesAdminServiceStub(config, session, request);
        String nameOfQueue = stub.getDLCQueue().getQueueName();
        String concatenatedParameters = "nameOfQueue=" + nameOfQueue;
        String pageNumberAsStr = request.getParameter("pageNumber");
        int msgCountPerPage = AndesConfigurationManager.readValue(
                AndesConfiguration.MANAGEMENT_CONSOLE_MESSAGE_BROWSE_PAGE_SIZE);

        Map<Integer, Long> pageNumberToMessageIdMap;
        if (null != request.getSession().getAttribute("pageNumberToMessageIdMap")) {
            pageNumberToMessageIdMap = (Map<Integer, Long>) request.getSession().getAttribute("pageNumberToMessageIdMap");
        } else {
            pageNumberToMessageIdMap = new HashMap<Integer, Long>();
        }

        int pageNumber = 0;
        int numberOfPages = 1;
        long totalMsgsInQueue;
        long startMessageIdOfPage;
        long nextMessageIdToRead = 0L;

        Message[] filteredMsgArray = null;
        if (null != pageNumberAsStr) {
            pageNumber = Integer.parseInt(pageNumberAsStr);
        }
        try {
            // The total number of messages depends on whether the filter was used or not
            if (DLCQueueUtils.isDeadLetterQueue(nameOfQueue)) {
                totalMsgsInQueue = stub.getTotalMessagesInQueue(nameOfQueue);
            } else {
                totalMsgsInQueue = stub.getNumberOfMessagesInDLCForQueue(nameOfQueue);
            }
            numberOfPages = (int) Math.ceil(((float) totalMsgsInQueue) / msgCountPerPage);

            if (pageNumberToMessageIdMap.size() > 0) {
                if (0 == pageNumber){
                    nextMessageIdToRead = 0;
                }
                else if (null != pageNumberToMessageIdMap.get(pageNumber)) {
                    nextMessageIdToRead = pageNumberToMessageIdMap.get(pageNumber);
                }
            }
            // The source of the messages depends on whether the filter was used or not
            if (DLCQueueUtils.isDeadLetterQueue(nameOfQueue)) {
                filteredMsgArray = stub.browseQueue(nameOfQueue, nextMessageIdToRead, msgCountPerPage);
            } else {
                filteredMsgArray = stub.getMessageInDLCForQueue(nameOfQueue, nextMessageIdToRead, msgCountPerPage);
            }
            if (null != filteredMsgArray && filteredMsgArray.length > 0) {
                startMessageIdOfPage = filteredMsgArray[0].getAndesMsgMetadataId();
                pageNumberToMessageIdMap.put(pageNumber, startMessageIdOfPage);
                nextMessageIdToRead = filteredMsgArray[filteredMsgArray.length - 1].getAndesMsgMetadataId() + 1;
                pageNumberToMessageIdMap.put((pageNumber + 1), nextMessageIdToRead);
                request.getSession().setAttribute("pageNumberToMessageIdMap", pageNumberToMessageIdMap);
            }
        } catch (AndesAdminServiceBrokerManagerAdminException e) {
            CarbonUIMessage.sendCarbonUIMessage(e.getFaultMessage().getBrokerManagerAdminException().getErrorMessage(),
                                                CarbonUIMessage.ERROR, request, e);
        }

        // When searched for a queue, the queue name should persist in the text box.
        String previouslySearchedQueueName = StringUtils.EMPTY;
        if (!DLCQueueUtils.isDeadLetterQueue(nameOfQueue)) {
            previouslySearchedQueueName = nameOfQueue;
        }
    %>
    <carbon:breadcrumb
            label="queue.content"
            resourceBundle="org.wso2.carbon.andes.ui.i18n.Resources"
            topPage="false"
            request="<%=request%>"/>

    <div id="middle">
        <h2><fmt:message key="dlc.queue.content"/> <%=nameOfQueue%>
        </h2>

        <div id="workArea">
            <table id="queueAddTable" class="styledLeft" style="width:100%">
                <thead>
                <tr>
                    <th colspan="2">Enter Queue Name to Filter</th>
                </tr>
                </thead>
                <tbody>
                <tr>
                    <td class="formRaw leftCol-big">Queue Name:</td>
                    <td><input type="text" id="queueName" value="<%= previouslySearchedQueueName %>">
                        <input id="searchButton" class="button" type="button"
                               onclick="return filterByQueue();" value="Filter">

                        <form id="dummyForm" action="dlc_messages_list.jsp" method="post">
                            <input type="hidden" name="nameOfQueue" id="filterQueueName" value=""/>
                        </form>
                    </td>
                </tr>
                </tbody>
            </table>
            <p>&nbsp;</p>

            <div id="iconArea">
                <table align="right">
                    <thead>
                    <tr align="right">
                        <%--Delete messages--%>
                            <% try {
                                if(stub.checkCurrentUserHasDeleteMessagesInDLCPermission()){ %>
                            <th align="right">
                                <a style="background-image: url(../admin/images/delete.gif);"
                                   class="icon-link"
                                   onclick="doDeleteDLC('<%=nameOfQueue%>')">Delete</a>
                            </th>
                            <% } else { %>
                            <th align="right">
                                <a style="background-image: url(../admin/images/delete.gif);"
                                   class="icon-link disabled-ahref"
                                   href="#">Delete</a>
                            </th>
                            <% }
                            } catch (AndesAdminServiceBrokerManagerAdminException e) { %>
                            <th align="right">
                                <a style="background-image: url(../admin/images/delete.gif);"
                                   class="icon-link disabled-ahref"
                                   href="#">Delete</a>
                            </th>
                            <% } %>


                        <%--Restore messages--%>
                            <% try {
                                if(stub.checkCurrentUserHasRestoreMessagesInDLCPermission()){ %>
                            <th align="right">
                                <a style="background-image: url(../admin/images/move.gif);"
                                   class="icon-link"
                                   onclick="deRestoreMessages('<%=nameOfQueue%>')">Restore</a>
                            </th>
                            <% } else { %>
                            <th align="right">
                                <a style="background-image: url(../admin/images/move.gif);"
                                   class="icon-link disabled-ahref"
                                   href="#">Restore</a>
                            </th>
                            <% }
                            } catch (AndesAdminServiceBrokerManagerAdminException e) { %>
                            <th align="right">
                                <a style="background-image: url(../admin/images/move.gif);"
                                   class="icon-link disabled-ahref"
                                   href="#">Restore</a>
                            </th>
                            <% } %>


                        <%--Reroute messages--%>
                            <% try {
                                if(stub.checkCurrentUserHasRerouteMessagesInDLCPermission()){ %>
                            <th align="right">
                                <a style="background-image: url(images/move.gif);"
                                   class="icon-link"
                                   onclick="doReRouteMessages('<%=nameOfQueue%>')">ReRoute</a>
                            </th>
                            <% } else { %>
                            <th align="right">
                                <a style="background-image: url(images/move.gif);"
                                   class="icon-link disabled-ahref"
                                   href="#">ReRoute</a>
                            </th>
                            <% }
                            } catch (AndesAdminServiceBrokerManagerAdminException e) { %>
                            <th align="right">
                                <a style="background-image: url(images/move.gif);"
                                   class="icon-link disabled-ahref"
                                   href="#">ReRoute</a>
                            </th>
                            <% } %>

                    </tr>
                    </thead>
                </table>
            </div>
            <input type="hidden" name="pageNumber" value="<%=pageNumber%>"/>
            <carbon:paginator pageNumber="<%=pageNumber%>" numberOfPages="<%=numberOfPages%>"
                              page="dlc_messages_list.jsp" pageNumberParameterName="pageNumber"
                              resourceBundle="org.wso2.carbon.andes.ui.i18n.Resources"
                              prevKey="prev" nextKey="next" parameters="<%=concatenatedParameters%>"
                              showPageNumbers="false"/>

            <table class="styledLeft" style="width:100%">
                <thead>
                <tr>
                    <th><input type="checkbox" name="selectAllCheckBox"
                               onClick="toggleCheck(this)"/></th>
                    <th><fmt:message key="message.contenttype"/></th>
                    <th><fmt:message key="message.messageId"/></th>
                    <th><fmt:message key="message.timestamp"/></th>
                    <th><fmt:message key="message.destination"/></th>
                    <th><fmt:message key="message.properties"/></th>
                    <th><fmt:message key="message.summary"/></th>
                </tr>
                </thead>
                <tbody>
                <%
                    if (null != filteredMsgArray) {
                        int count = 1;
                        for (Message queueMessage : filteredMsgArray) {
                            if (null != queueMessage) {
                                String msgProperties = queueMessage.getMsgProperties();
                                String contentType = queueMessage.getContentType();
                                String[] messageContent = queueMessage.getMessageContent();
                                String dlcMsgDestination = queueMessage.getDlcMsgDestination();
                                long contentDisplayID = queueMessage.getJMSTimeStamp()+count;
                                count ++;
                %>
                <tr>
                    <td><input type="checkbox" name="checkbox" onClick="checkSelectAll(this)"
                               value="<%= queueMessage.getAndesMsgMetadataId() %>"/></td>
                    <td><img src="images/<%= contentType.toLowerCase()%>.png"
                             alt=""/>&nbsp;&nbsp;<%= contentType%>
                    </td>
                    <td><%= queueMessage.getJMSMessageId()%>
                    </td>
                    <td><%= queueMessage.getJMSTimeStamp()%>
                    </td>
                    <td><%= dlcMsgDestination %>
                    </td>
                    <td><%= msgProperties%>
                    </td>
                    <td>
                        <%=StringEscapeUtils.escapeHtml(messageContent[0])%>
                        <!-- This is converted to a POST to avoid message length eating up the URI request length. -->
                        <form name="msgViewForm<%=contentDisplayID%>" method="POST" action="message_content.jsp">
                            <input type="hidden" name="message" value="<%=StringEscapeUtils.escapeHtml(messageContent[1])%>" />
                            <a href="javascript:document.msgViewForm<%=contentDisplayID%>.submit()">&nbsp;&nbsp;&nbsp;more..</a>
                        </form>
                    </td>
                </tr>

                <%
                            }
                        }
                    }
                %>
                </tbody>
            </table>

        </div>
    </div>
    <div>
        <form id="deleteForm" name="input" action="dlc_messages_list.jsp" method="get"><input
                type="HIDDEN"
                name="deleteMsg"
                value=""/>
            <input type="HIDDEN"
                   name="nameOfQueue"
                   value=""/>
            <input type="HIDDEN"
                   name="msgList"
                   value=""/></form>
        <form id="restoreForm" name="input" action="dlc_messages_list.jsp" method="get"><input
                type="HIDDEN"
                name="restoreMsgs"
                value=""/>
            <input type="HIDDEN"
                   name="nameOfQueue"
                   value=""/>
            <input type="HIDDEN"
                   name="msgList"
                   value=""/></form>
    </div>
</fmt:bundle>
