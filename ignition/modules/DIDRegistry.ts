// SPDX-License-Identifier: MIT

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("DIDRegistry", (m) => {
    const DIDReg = m.contract("DIDRegistry");
    return { DIDReg };
});