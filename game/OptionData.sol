//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../owner/AdminRole.sol";


contract OptionData is AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => EnumerableSet.UintSet) private accWeaponList;

    function getAccWeaponList(address _acc)
        public view
        returns (uint256[] memory _nftList)
    {
        _nftList = new uint256[](accWeaponList[_acc].length());
        for (uint256 i=0; i< accWeaponList[_acc].length(); i++){
            _nftList[i] = accWeaponList[_acc].at(i);
        }
    }

    function accWeaponContains(address _acc, uint256 _nftNo)
        public view
        returns (bool)
    {
        return accWeaponList[_acc].contains(_nftNo);
    }

    function accWeaponAt(address _acc, uint256 _index)
        public view
        returns (uint256)
    {
        return accWeaponList[_acc].at(_index);
    }

    function accWeaponListLength(address _acc)
        public view
        returns (uint256)
    {
        return accWeaponList[_acc].length();
    }

    // operate
    function addAccWeapon(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accWeaponList[_acc].add(_nftNo);
    }

    function removeAccWeapon(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accWeaponList[_acc].remove(_nftNo);
    }
}
