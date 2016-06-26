/*
 * Copyright (c) 2016, WSO2 Inc. (http://wso2.com) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.wso2.carbon.andes.service.types;

import io.swagger.annotations.ApiModel;
import io.swagger.annotations.ApiModelProperty;

import java.util.ArrayList;
import java.util.List;

/**
 * A container class for messages. This will also have other properties based on offsets and limits.
 */
@ApiModel(value = "Message Container", description = "A container class for messages.")
public class MessagesContainer {
    @ApiModelProperty(value = "Total number of messages.", required = true)
    private long totalMessages = 0;
    @ApiModelProperty(value = "Url for the next set of messages.")
    private String next = "";
    @ApiModelProperty(value = "Url for the previous set of messages.")
    private String previous = "";
    @ApiModelProperty(value = "The list of messages.", required = true)
    private List<Message> messages = new ArrayList<>();

}
