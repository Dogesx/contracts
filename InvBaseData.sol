//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./owner/AdminRole.sol";


contract InvBaseData is AdminRole {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => address) public bindDict;
    mapping(address => EnumerableSet.AddressSet) private beInvitedList;
    mapping(address => uint256) public accBoxesRwd;

    function getBindAcc(address _acc)
        public view
        returns (address)
    {
        return bindDict[_acc];
    }

    function getBeinvList(address _acc)
        public view
        returns (address[] memory _beInvited)
    {
        _beInvited = new address[](beInvitedList[_acc].length());
        for (uint256 i=0; i< beInvitedList[_acc].length(); i++){
            _beInvited[i] = beInvitedList[_acc].at(i);
        }
    }

    function beinvContains(address _acc, address _beinvAcc)
        public view
        returns (bool)
    {
        return beInvitedList[_acc].contains(_beinvAcc);
    }

    function beinvAt(address _acc, uint256 _index)
        public view
        returns (address)
    {
        return beInvitedList[_acc].at(_index);
    }

    function beinvLength(address _acc)
        public view
        returns (uint256)
    {
        return beInvitedList[_acc].length();
    }


    function setBindAcc(address _acc, address _bindAcc)
        public onlyAdmin
    {
        bindDict[_acc] = _bindAcc;
    }

    function addBindAcc(address _acc, address _bindAcc)
        public onlyAdmin
    {
        bindDict[_acc] = _bindAcc;
        beInvitedList[_bindAcc].add(_acc);
    }

    function removeBindAcc(address _acc)
        public onlyAdmin
    {
        beInvitedList[bindDict[_acc]].remove(_acc);
        delete bindDict[_acc];
    }

    function addBeinv(address _acc, address _bindAcc)
        public onlyAdmin
    {
        beInvitedList[_acc].add(_bindAcc);
    }

    function removeBeinv(address _acc, address _bindAcc)
        public onlyAdmin
    {
        beInvitedList[_acc].remove(_bindAcc);
    }

    function setBoxesRwd(address _acc, uint256 _value)
        public onlyAdmin
    {
        accBoxesRwd[_acc] = _value;
    }

    function addBoxesRwd(address _acc, uint256 _value)
        public onlyAdmin
    {
        accBoxesRwd[_acc] += _value;
    }

    function subBoxesRwd(address _acc, uint256 _value)
        public onlyAdmin
    {
        accBoxesRwd[_acc] -= _value;
    }

}
