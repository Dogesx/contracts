//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./owner/AdminRole.sol";


contract FightData is AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    mapping(address => EnumerableSet.UintSet) private accHeroList;
    mapping(uint256 => FightInfo) public heroFightInfo;

    struct FightInfo{
        uint32 startTime;
        uint32 rewardTime;
        uint256 reward;
        uint256 rewardPreTl;
        address nftFrom;
    }

    function getAccFightHeroInfoList(address _acc)
        public view
        returns (uint256[] memory _nftList, uint256[4][] memory _infoList)
    {
        _nftList = new uint256[](accHeroList[_acc].length());
        _infoList = new uint256[4][](accHeroList[_acc].length());
        for (uint256 i=0; i< accHeroList[_acc].length(); i++){
            _nftList[i] = accHeroList[_acc].at(i);
            _infoList[i] = [heroFightInfo[_nftList[i]].startTime, heroFightInfo[_nftList[i]].rewardTime, heroFightInfo[_nftList[i]].reward, heroFightInfo[_nftList[i]].rewardPreTl];
        }
    }

    function getAccFightHeroIdList(address _acc)
        public view
        returns (uint256[] memory _nftList)
    {
        _nftList = new uint256[](accHeroList[_acc].length());
        for (uint256 i=0; i< accHeroList[_acc].length(); i++){
            _nftList[i] = accHeroList[_acc].at(i);
        }
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


    function addFightHero(address _acc, uint256 _nftNo, uint256 _reward, uint32 _startTime, uint32 _rewardTime)
        public onlyAdmin
    {
        accHeroList[_acc].add(_nftNo);
        heroFightInfo[_nftNo] = FightInfo({
            startTime: _startTime,
            rewardTime: _rewardTime,
            reward: _reward,
            rewardPreTl: 0,
            nftFrom: _acc
        });
    }

    function clearFightReward(uint256 _nftNo)
        public onlyAdmin
        returns (uint256 _rwd)
    {
        _rwd = heroFightInfo[_nftNo].reward + heroFightInfo[_nftNo].rewardPreTl;
        heroFightInfo[_nftNo].reward = 0;
        heroFightInfo[_nftNo].rewardPreTl = 0;
    }


    function continueFightHero(uint256 _nftNo, uint256 _reward, uint256 _rewardPreAdd, uint32 _startTime, uint32 _rewardTime)
        public onlyAdmin
    {
        heroFightInfo[_nftNo].startTime = _startTime;
        heroFightInfo[_nftNo].rewardTime = _rewardTime;
        heroFightInfo[_nftNo].reward = _reward;
        if (_rewardPreAdd > 0){
            heroFightInfo[_nftNo].rewardPreTl += _rewardPreAdd;
        }
    }

    function exitFightHero(address _acc, uint256 _nftNo)
        public onlyAdmin
        returns (uint256 _rwd)
    {
        _rwd = heroFightInfo[_nftNo].reward + heroFightInfo[_nftNo].rewardPreTl;
        accHeroList[_acc].remove(_nftNo);
        delete heroFightInfo[_nftNo];
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

    function setFightHeroInfo(address _acc, uint256 _nftNo, uint256 _reward, uint256 _rewardPreTl, uint32 _startTime, uint32 _rewardTime)
        public onlyAdmin
    {
        heroFightInfo[_nftNo] = FightInfo({
            startTime: _startTime,
            rewardTime: _rewardTime,
            reward: _reward,
            rewardPreTl: _rewardPreTl,
            nftFrom: _acc
        });
    }

}
