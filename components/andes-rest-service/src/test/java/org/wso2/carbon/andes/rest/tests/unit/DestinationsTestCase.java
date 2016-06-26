package org.wso2.carbon.andes.rest.tests.unit;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import org.json.JSONException;
import org.json.JSONObject;
import org.mockito.Mockito;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.wso2.carbon.andes.core.AndesException;
import org.wso2.carbon.andes.rest.tests.Constants;
import org.wso2.carbon.andes.service.exceptions.DestinationManagerException;
import org.wso2.carbon.andes.service.exceptions.MessageManagerException;
import org.wso2.carbon.andes.service.exceptions.mappers.DestinationNotFoundMapper;
import org.wso2.carbon.andes.service.exceptions.mappers.InternalServerErrorMapper;
import org.wso2.carbon.andes.service.exceptions.mappers.MessageNotFoundMapper;
import org.wso2.carbon.andes.service.internal.AndesRESTService;
import org.wso2.carbon.andes.service.managers.DestinationManagerService;
import org.wso2.carbon.andes.service.managers.MessageManagerService;
import org.wso2.carbon.andes.service.types.Destination;
import org.wso2.msf4j.MicroservicesRunner;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

import static org.mockito.Matchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Created by hemikak on 6/26/16.
 */
public class DestinationsTestCase {
    private static final Logger log = LoggerFactory.getLogger(DestinationsTestCase.class);
    private MicroservicesRunner microservicesRunner;
    private AndesRESTService andesRESTService;
    private DestinationNotFoundMapper destinationNotFoundMapper = new DestinationNotFoundMapper();
    private InternalServerErrorMapper internalServerErrorMapper = new InternalServerErrorMapper();
    private MessageNotFoundMapper messageNotFoundMapper = new MessageNotFoundMapper();

    /**
     * Initializes the tests.
     *
     * @throws AndesException
     */
    @BeforeClass
    public void setupService() throws AndesException {
        microservicesRunner = new MicroservicesRunner(Constants.PORT);
        andesRESTService = new AndesRESTService();
        microservicesRunner.addExceptionMapper(destinationNotFoundMapper,
                internalServerErrorMapper, messageNotFoundMapper).deploy(andesRESTService).start();
    }

    /**
     * Cleans up the microservice runner and the andes service.
     */
    @AfterClass
    public void cleanUpServices() {
        microservicesRunner.stop();
        if (microservicesRunner.getMsRegistry().getHttpServices().contains(andesRESTService)) {
            microservicesRunner.getMsRegistry().removeService(andesRESTService);
        }
        andesRESTService = null;
        microservicesRunner = null;
    }

    /**
     * Tests that a 500 is received when an {@link DestinationManagerException} occurs while browsing messages.
     *
     * @throws AndesException
     * @throws IOException
     * @throws JSONException
     * @throws MessageManagerException
     * @throws DestinationManagerException
     */
    @Test(groups = {"wso2.mb", "rest"})
    public void getDestinationsThrowDestinationManagerErrorTestCase() throws AndesException, IOException, JSONException,
            MessageManagerException, DestinationManagerException {
        DestinationManagerService destinationManagerService = mock(DestinationManagerService.class);
        when(destinationManagerService.getDestinations(Mockito.anyString(), Mockito.anyString(), Mockito.anyString(), Mockito.anyInt(), Mockito.anyInt()))
                .thenThrow(new DestinationManagerException("Internal Error"));

        andesRESTService.setDestinationManagerService(destinationManagerService);

        DefaultHttpClient httpClient = new DefaultHttpClient();
        HttpGet getRequest = new HttpGet(Constants.BASE_URL + "/amqp-0-91/destination-type/queue");
        getRequest.addHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON);

        HttpResponse response = httpClient.execute(getRequest);

        validateExceptionHandling(response.getEntity());
        Assert.assertEquals(response.getStatusLine().getStatusCode(),
                Response.Status.INTERNAL_SERVER_ERROR.getStatusCode(), "500 not received");

        verify(destinationManagerService, atLeastOnce()).getDestination(Mockito.anyString(), Mockito.anyString(),
                Mockito.anyString());

        httpClient.getConnectionManager().shutdown();
    }

    /**
     * Tests that a 200 is received when requested for messages with default query params.
     *
     * @throws AndesException
     * @throws IOException
     * @throws JSONException
     * @throws MessageManagerException
     * @throws DestinationManagerException
     */
    @Test(groups = {"wso2.mb", "rest"})
    public void getDestinationsWithNoQueryParamsTestCase() throws AndesException, IOException, JSONException,
            MessageManagerException, DestinationManagerException {
        DestinationManagerService destinationManagerService = mock(DestinationManagerService.class);
        when(destinationManagerService.getDestinations(Mockito.anyString(), Mockito.anyString(), Mockito.anyString(), Mockito.anyInt(), Mockito.anyInt()))
                .thenReturn(new ArrayList<Destination>());

        andesRESTService.setDestinationManagerService(destinationManagerService);

        DefaultHttpClient httpClient = new DefaultHttpClient();
        HttpGet getRequest = new HttpGet(Constants.BASE_URL + "/amqp-0-91/destination-type/queue/");
        getRequest.addHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON);

        HttpResponse response = httpClient.execute(getRequest);
        Assert.assertEquals(response.getStatusLine().getStatusCode(), Response.Status.OK.getStatusCode(),
                "200 not received");

        verify(destinationManagerService, atLeastOnce()).getDestinations(Mockito.anyString(),
                Mockito.anyString(), Mockito.anyString(), eq(0), eq(20));

        httpClient.getConnectionManager().shutdown();
    }

    /**
     * Tests that a 200 is received when requested for messages with content query param only.
     *
     * @throws AndesException
     * @throws IOException
     * @throws JSONException
     * @throws MessageManagerException
     * @throws DestinationManagerException
     */
    @Test(groups = {"wso2.mb", "rest"})
    public void getDestinationsWithSearchOnlyTestCase() throws AndesException, IOException, JSONException,
            MessageManagerException, DestinationManagerException {
        Destination destinationQ1 = new Destination();
        destinationQ1.setDestinationName("Q-1");

        Destination destinationQ2 = new Destination();
        destinationQ2.setDestinationName("Q-2");

        DestinationManagerService destinationManagerService = mock(DestinationManagerService.class);
        when(destinationManagerService.getDestinations(Mockito.anyString(), Mockito.anyString(), Mockito.anyString(), Mockito.anyInt(), Mockito.anyInt()))
                .thenReturn(Stream.of(destinationQ1, destinationQ2).collect(Collectors.toList()));

        andesRESTService.setDestinationManagerService(destinationManagerService);

        DefaultHttpClient httpClient = new DefaultHttpClient();
        HttpGet getRequest = new HttpGet(Constants.BASE_URL + "/amqp-0-91/destination-type/queue");
        getRequest.addHeader(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON);

        HttpResponse response = httpClient.execute(getRequest);
        JSONObject jsonObject = new JSONObject();
        if (response.getEntity() != null) {
            jsonObject = new JSONObject(EntityUtils.toString(response.getEntity()));
        }
        log.info("JSOOOOON : " + jsonObject.toString());
        Assert.assertEquals(response.getStatusLine().getStatusCode(), Response.Status.OK.getStatusCode(),
                "200 not received");

//        verify(messageManagerService, atLeastOnce()).getMessagesOfDestinationByMessageID(Mockito.anyString(),
//                Mockito.anyString(), Mockito.anyString(), eq(true), Mockito.anyLong(), Mockito.anyInt());

        httpClient.getConnectionManager().shutdown();
    }

    /**
     * Validates that required content are there in error response.
     *
     * @param responseEntity The response content.
     * @throws IOException
     * @throws JSONException
     */
    public void validateExceptionHandling(HttpEntity responseEntity) throws IOException, JSONException {
        JSONObject jsonObject = new JSONObject();
        if (responseEntity != null) {
            jsonObject = new JSONObject(EntityUtils.toString(responseEntity));
        }
        Assert.assertTrue(null != jsonObject.get("title"), "Title for the error is missing.");
        Assert.assertTrue(null != jsonObject.get("code"), "Error code is missing.");
        Assert.assertTrue(null != jsonObject.get("message"), "A message is required for the error.");
    }
}
