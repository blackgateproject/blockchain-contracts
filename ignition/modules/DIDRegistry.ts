// SPDX-License-Identifier: MIT

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import fundAccount from "../../source/fundAccount";
export default buildModule("DIDRegistry", (m) => {
    const DIDReg = m.contract("DIDRegistry");

    const task = m.call("fundAccount", fundAccount, DIDReg.address, "1.0");
    return { DIDReg };
});