// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../owner/AdminRole.sol";

contract GSToken is ERC20Burnable, AdminRole {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){}

    function mint(address _to, uint256 _amount) public onlyAdmin {
        _mint(_to, _amount);
    }
}
