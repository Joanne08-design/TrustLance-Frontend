// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {TrustLance} from "../src/TrustLance.sol";

contract DeployTrustLance is Script {
    function run() external returns (TrustLance) {
        vm.startBroadcast();

        TrustLance trustLance = new TrustLance();

        vm.stopBroadcast();

        return trustLance;
    }
}