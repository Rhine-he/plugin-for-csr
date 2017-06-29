// (c) 2014 Don Coleman
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/* global cordova, module */
"use strict";

// JS->Native交互时，对ArrayBuffer进行uint8ToBase64  ---自注
var stringToArrayBuffer = function(str) {
    var ret = new Uint8Array(str.length); // Unit8Array,8位(2字节)无符号整数值的类型化数组
    for (var i = 0; i < str.length; i++) {
        ret[i] = str.charCodeAt(i); // 返回指定位置的字符的Unicode编码。返回值是0～65535之间的倍数
    }
    // TODO would it be better to return Uint8Array?
    return ret.buffer;
};

var base64ToArrayBuffer = function(b64) {
    return stringToArrayBuffer(atob(b64));
};

function massageMessageNativeToJs(message) {
    if (message.CDVType == 'ArrayBuffer') {
        message = base64ToArrayBuffer(message.data);
    }
    return message;
}

// Cordova 3.6 doesn't unwrap ArrayBuffers in nested data structures
// https://github.com/apache/cordova-js/blob/94291706945c42fd47fa632ed30f5eb811080e95/src/ios/exec.js#L107-L122
function convertToNativeJS(object) {
    Object.keys(object).forEach(function (key) {
        var value = object[key];
        object[key] = massageMessageNativeToJs(value);
        if (typeof(value) === 'object') {
            convertToNativeJS(value);
        }
    });
}

module.exports = {

    startScan: function (success, failure) {
        var successWrapper = function(peripheral) {
            convertToNativeJS(peripheral);
            success(peripheral);
        };
        cordova.exec(successWrapper, failure, 'csrmesh', 'startScan');
    },
    stopScan:function(success,failure){
    	cordova.exec(success, failure, 'csrmesh', 'stopScan');
    },
    connect: function (devicei_uuid, success, failure) {
        var successWrapper = function(peripheral) {
            convertToNativeJS(peripheral);
            success(peripheral);
        };
        cordova.exec(successWrapper, failure, 'csrmesh', 'connect', [devicei_uuid]);
    },
    // 自加，设置mesh网络的密码；参数[password]
    setPassword:function(password, success, failure){
    	cordova.exec(success, failure, "csrmesh", "setPassword",[password]);
    },
    // 自加，获取unAssociated的设备，无参数；回调返回值:unAssociated设备的deviceUUID
    getAssociableDevice:function(success, failure){
    	cordova.exec(success, failure, "csrmesh", "getAssociableDevice");
    },
    // 自加，关联灯泡，一个参数 [deviceUUID]
    associate: function(deviceUUID, success, failure){
    	cordova.exec(success, failure, "csrmesh", "associate", [deviceUUID]);
    },
    // 自加，开启灯泡，（控制连接到的设备，参数两个[deviceId, state]）
    setPower: function(deviceId, state, success, failure) {
    	cordova.exec(success, failure, "csrmesh", "setPower",[deviceId, state]);
    },
    // 自加，设置灯泡颜色，两个参数[deviceId, color]）
    setColor: function (deviceId, color, success, failure) {
        cordova.exec(success, failure, "csrmesh", "setColor", [deviceId, color]);
    },
    // 自加， 设置灯泡亮度的强度，参数两个[deviceId, state]
    setBrightness: function(deviceId, intensity, success, failure){
    	cordova.exec(success, failure, "csrmesh", "setBrightness", [deviceId, intensity]);
    },
//    getDevId: function(devicei_uuid, success, failure){
//    	cordova.exec(success, failure, "BLE", "getDevId", [devicei_uuid]);
//    },
    // 自加，设置灯泡的分组，两个参数[deviceId, groupIds(包含groupId的数组)]
    setGroups: function(deviceId, groupIds, success, failure){
    	cordova.exec(success, failure, "csrmesh", "setGroups", [deviceId, groupIds]);
    },
    // 自加，重置灯泡的association信息，一个参数[deviceId]
    resetDevice: function(deviceId, success, failure){
    	cordova.exec(success, failure, "csrmesh", "reset", [deviceId]);
    },
    // 自加，设置下一个设备的deviceId，参数[NextDeviceId]
    setNextDeviceId: function(nextDeviceId, success, failure){
    	cordova.exec(success, failure, "csrmesh", "setNextDeviceId", [nextDeviceId]);
    }
};
