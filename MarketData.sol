//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./owner/AdminRole.sol";


contract MarketData is AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => uint256[2][]) public soldHeroRecords;
    EnumerableSet.UintSet private sellHeroList;
    mapping(address => EnumerableSet.UintSet) private accHeroList;
    mapping(uint256 => SellProd) public prodHeroInfo;

    mapping(address => uint256[2][]) public soldWeaponRecords;
    EnumerableSet.UintSet private sellWeaponList;
    mapping(address => EnumerableSet.UintSet) private accWeaponList;
    mapping(uint256 => SellProd) public prodWeaponInfo;

    struct SellProd{
        uint256 price;
        address nftFrom;
    }


    function getAccSoldHeroRecords(address _acc, uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _records)
    {
        uint256 _initV = _endIdx - _startIdx + 1;
        if (soldHeroRecords[_acc].length < _startIdx + 1) {
            _initV = 0;
        } else if (soldHeroRecords[_acc].length < _endIdx + 1 ) {
            _initV = soldHeroRecords[_acc].length - _startIdx;
        }
        _records = new uint256[2][](_initV);
        _startIdx = soldHeroRecords[_acc].length - _startIdx;
        for(uint256 i=0; i<_initV; i++ ){
            _records[i] = soldHeroRecords[_acc][_startIdx - 1 - i];
        }
    }

    function getAccSellHeroList(address _acc)
        public view
        returns (uint256[2][] memory _nftList)
    {
        _nftList = new uint256[2][](accHeroList[_acc].length());
        for (uint256 i=0; i< accHeroList[_acc].length(); i++){
            _nftList[i] = [accHeroList[_acc].at(i), prodHeroInfo[accHeroList[_acc].at(i)].price];
        }
    }

    function getAllSellHeroList(uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _nftList)
    {
        if (_startIdx >= sellHeroList.length()) {
            _endIdx = _startIdx;
        }
        if (_endIdx > sellHeroList.length()) {
            _endIdx = sellHeroList.length();
        }
        _nftList = new uint256[2][](_endIdx - _startIdx);
        for(uint256 i=_startIdx; i<_endIdx; i++ ){
            uint256 _nftNo = sellHeroList.at(i);
            _nftList[i - _startIdx] = [_nftNo, prodHeroInfo[_nftNo].price];
        }
    }

    function getSellHeroInfo(uint256 _nftNo)
        public view
        returns (bool, uint256, address)
    {
        return (sellHeroList.contains(_nftNo), prodHeroInfo[_nftNo].price, prodHeroInfo[_nftNo].nftFrom);
    }

    function addSellHero(address _acc, uint256 _nftNo, uint256 _price)
        public onlyAdmin
    {
        sellHeroList.add(_nftNo);
        accHeroList[_acc].add(_nftNo);
        prodHeroInfo[_nftNo] = SellProd({
            price: _price,
            nftFrom: _acc
        });
    }

    function cancelSellHero(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        sellHeroList.remove(_nftNo);
        accHeroList[_acc].remove(_nftNo);
        delete prodHeroInfo[_nftNo];
    }

    function buySellHero(uint256 _nftNo)
        public onlyAdmin
    {
        soldHeroRecords[prodHeroInfo[_nftNo].nftFrom].push([_nftNo, prodHeroInfo[_nftNo].price]);
        sellHeroList.remove(_nftNo);
        accHeroList[prodHeroInfo[_nftNo].nftFrom].remove(_nftNo);
        delete prodHeroInfo[_nftNo];
    }

    function accHeroContains(address _acc, uint256 _nftNo)
        public view
        returns (bool)
    {
        return accHeroList[_acc].contains(_nftNo);
    }

    function accHeroAt(address _acc, uint256 _index)
        public view
        returns (uint256)
    {
        return accHeroList[_acc].at(_index);
    }

    function accHeroListLength(address _acc)
        public view
        returns (uint256)
    {
        return accHeroList[_acc].length();
    }

    function allHerosContains(uint256 _nftNo)
        public view
        returns (bool)
    {
        return sellHeroList.contains(_nftNo);
    }

    function allHerosAt(uint256 _index)
        public view
        returns (uint256)
    {
        return sellHeroList.at(_index);
    }

    function allHerosLength()
        public view
        returns (uint256)
    {
        return sellHeroList.length();
    }


    function getAccSoldWeaponRecords(address _acc, uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _records)
    {
        uint256 _initV = _endIdx - _startIdx + 1;
        if (soldWeaponRecords[_acc].length < _startIdx + 1) {
            _initV = 0;
        } else if (soldWeaponRecords[_acc].length < _endIdx + 1 ) {
            _initV = soldWeaponRecords[_acc].length - _startIdx;
        }
        _records = new uint256[2][](_initV);
        _startIdx = soldWeaponRecords[_acc].length - _startIdx;
        for(uint256 i=0; i<_initV; i++ ){
            _records[i] = soldWeaponRecords[_acc][_startIdx - 1 - i];
        }
    }

    function getAccSellWeaponList(address _acc)
        public view
        returns (uint256[2][] memory _nftList)
    {
        _nftList = new uint256[2][](accWeaponList[_acc].length());
        for (uint256 i=0; i< accWeaponList[_acc].length(); i++){
            _nftList[i] = [accWeaponList[_acc].at(i), prodWeaponInfo[accWeaponList[_acc].at(i)].price];
        }
    }

    function getAllSellWeaponList(uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _nftList)
    {
        if (_startIdx >= sellWeaponList.length()) {
            _endIdx = _startIdx;
        }
        if (_endIdx > sellWeaponList.length()) {
            _endIdx = sellWeaponList.length();
        }
        _nftList = new uint256[2][](_endIdx - _startIdx);
        for(uint256 i=_startIdx; i<_endIdx; i++ ){
            uint256 _nftNo = sellWeaponList.at(i);
            _nftList[i - _startIdx] = [_nftNo, prodWeaponInfo[_nftNo].price];
        }
    }

    function getSellWeaponInfo(uint256 _nftNo)
        public view
        returns (bool, uint256, address)
    {
        return (sellWeaponList.contains(_nftNo), prodWeaponInfo[_nftNo].price, prodWeaponInfo[_nftNo].nftFrom);
    }

    function addSellWeapon(address _acc, uint256 _nftNo, uint256 _price)
        public onlyAdmin
    {
        sellWeaponList.add(_nftNo);
        accWeaponList[_acc].add(_nftNo);
        prodWeaponInfo[_nftNo] = SellProd({
            price: _price,
            nftFrom: _acc
        });
    }

    function cancelSellWeapon(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        sellWeaponList.remove(_nftNo);
        accWeaponList[_acc].remove(_nftNo);
        delete prodWeaponInfo[_nftNo];
    }

    function buySellWeapon(uint256 _nftNo)
        public onlyAdmin
    {
        soldWeaponRecords[prodWeaponInfo[_nftNo].nftFrom].push([_nftNo, prodWeaponInfo[_nftNo].price]);
        sellWeaponList.remove(_nftNo);
        accWeaponList[prodWeaponInfo[_nftNo].nftFrom].remove(_nftNo);
        delete prodWeaponInfo[_nftNo];
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

    function allWeaponsContains(uint256 _nftNo)
        public view
        returns (bool)
    {
        return sellWeaponList.contains(_nftNo);
    }

    function allWeaponsAt(uint256 _index)
        public view
        returns (uint256)
    {
        return sellWeaponList.at(_index);
    }

    function allWeaponsLength()
        public view
        returns (uint256)
    {
        return sellWeaponList.length();
    }


    function addAccHero(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accHeroList[_acc].add(_nftNo);
    }

    function removeAccHero(address _acc, uint256 _nftNo)
        public onlyAdmin
    {
        accHeroList[_acc].remove(_nftNo);
    }

    function addAllHeros(uint256 _nftNo)
        public onlyAdmin
    {
        sellHeroList.add(_nftNo);
    }

    function removeAllHeros(uint256 _nftNo)
        public onlyAdmin
    {
        sellHeroList.remove(_nftNo);
    }

    function setProdHeroInfo(address _acc, uint256 _nftNo, uint256 _price)
        public onlyAdmin
    {
        prodHeroInfo[_nftNo] = SellProd({price: _price, nftFrom: _acc});
    }

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

    function addAllWeapons(uint256 _nftNo)
        public onlyAdmin
    {
        sellWeaponList.add(_nftNo);
    }

    function removeAllWeapons(uint256 _nftNo)
        public onlyAdmin
    {
        sellWeaponList.remove(_nftNo);
    }

    function setProdWeaponInfo(address _acc, uint256 _nftNo, uint256 _price)
        public onlyAdmin
    {
        prodWeaponInfo[_nftNo] = SellProd({price: _price, nftFrom: _acc});
    }

}
