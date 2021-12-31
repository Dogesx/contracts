// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdminRole.sol";

contract SwitchAdmin is AdminRole {
    uint8 public isPause; 

    modifier isOpen() {
        require(isPause == 0, "Pause!");
        _;
    }

    function setPause(uint8 _isPause) public onlyAdmin {
        isPause = _isPause;
    }

}
