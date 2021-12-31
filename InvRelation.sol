//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./owner/SwitchAdmin.sol";

interface IData {

    function getBindAcc(address _acc) external view returns (address);
    function getBeinvList(address _acc) external view returns (address[] memory _beInvited);
    function beinvLength(address _acc) external view returns (uint256);
    function accBoxesRwd(address _acc) external view returns (uint256);

    function addBindAcc(address _acc, address _bindAcc) external;
    function removeBindAcc(address _acc) external;
    function addBoxesRwd(address _acc, uint256 _value) external;
    function subBoxesRwd(address _acc, uint256 _value) external;
}

contract InvRelation is SwitchAdmin {
    using SafeERC20 for IERC20;

    IData public dataObj;
    IERC20 public rewardToken;

    uint32 public beinvBoxRwdRate;

    event BindAccEvent(address indexed user, address acc);
    event DrawRewardEvent(address indexed user, uint256 value);

    constructor(
        IData dataObj_,
        IERC20 rewardToken_
    ){
        dataObj = dataObj_;
        rewardToken = rewardToken_;

        beinvBoxRwdRate = 7;
    }

    function getBindAcc(address _acc)
        public view
        returns (address)
    {
        return dataObj.getBindAcc(_acc);
    }

    function getBeinvBoxesRwd(address _acc)
        public view
        returns (uint256)
    {
        return dataObj.accBoxesRwd(_acc);
    }

    function getInfo(address _acc)
        public view
        returns (uint256, uint256)
    {
        return (dataObj.beinvLength(_acc), dataObj.accBoxesRwd(_acc));
    }

    function bindAcc(address _bindAcc)
        public isOpen
    {
        require (_bindAcc != msg.sender, "Param error");
        require (dataObj.getBindAcc(msg.sender) == address(0), "It's already bound");

        // bind
        dataObj.addBindAcc(msg.sender, _bindAcc);

        emit BindAccEvent(msg.sender, _bindAcc);
    }

    function drawReward()
        public isOpen
    {
        uint256 _reward = dataObj.accBoxesRwd(msg.sender);
        require(_reward > 0, "Reward None");

        dataObj.subBoxesRwd(msg.sender, _reward);
        rewardToken.safeTransfer(msg.sender, _reward);

        emit DrawRewardEvent(msg.sender, _reward);
    }

    function beinvedAddBoxesRwd(address _beinvAcc, uint256 _amount)
        public onlyAdmin
    {
        address _bindAcc = dataObj.getBindAcc(_beinvAcc);
        if (_bindAcc == address(0)) { return; }
        uint256 _rwd = _amount * beinvBoxRwdRate / 100;
        dataObj.addBoxesRwd(_bindAcc, _rwd);
    }

    // admin
    function setDataObj(address _addr) public onlyAdmin {
        dataObj = IData(_addr);
    }

    function setRewardToken(address _addr) public onlyAdmin {
        rewardToken = IERC20(_addr);
    }

    function setBeinvBoxRwdRate(uint32 _value) public onlyAdmin {
        beinvBoxRwdRate = _value;
    }

    function transferRewardToken(address addr_, address _token, uint256 amount) external onlyAdmin {
        IERC20(_token).safeTransfer(addr_, amount);
    }


}
