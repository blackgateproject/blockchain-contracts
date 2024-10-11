// SPDX-License-Identifier: MIT

// WIP:: Too braindead to figure this out right now

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import fundAccount from "../../source/fundAccount";
export default buildModule("DIDRegistry", (m) => {
    const DIDReg = m.contract("DIDRegistry");

    m.afterDeploy(async () => {
        const accounts = DIDReg.address;

    }

    return { DIDReg };
});