//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./owner/SwitchAdmin.sol";

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IBurnERC20 is IERC20{
    function burn(uint256 amount) external;
}

interface IWGasCoin {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IData {
    function heroFightInfo(uint256 _nftNo) external view returns (uint32 _startT, uint32 _rewardT, uint256 _reward, uint256 _rewardPre, address _nftFrom);
    function getAccFightHeroInfoList(address _acc) external view returns (uint256[] memory _nftList, uint256[4][] memory _infoList);
    function accHeroListLength(address _acc) external view returns (uint256);

    function addFightHero(address _acc, uint256 _nftNo, uint256 _reward, uint32 _startTime, uint32 _rewardTime) external;
    function continueFightHero(uint256 _nftNo, uint256 _reward, uint256 _rewardPreAdd, uint32 _startTime, uint32 _rewardTime) external;
    function clearFightReward(uint256 _nftNo) external returns (uint256 _rwd);
    function clearFightPreTlReward(uint256 _nftNo) external returns (uint256 _rwd);
    function exitFightHero(address _acc, uint256 _nftNo) external returns (uint256 _rwd);

}

interface IHeroNFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);
    function getNFTSlotWeapons(uint256 _nftNo) external view returns (uint256[2] memory);
    function getSlotsList(uint256[] memory _nftList) external view returns (uint256[2][] memory _slotsList);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IWeaponNFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract HeroFight is SwitchAdmin, ERC721Holder {
    using SafeERC20 for IBurnERC20;

    address public immutable wGasCoin;
    IData public dataObj;
    IBurnERC20 public stakeToken;
    IBurnERC20 public rewardToken;
    IHeroNFTCard public heroCard;
    IWeaponNFTCard public weaponCard;

    mapping(uint16 => uint16) public weaponAddition;
    mapping(uint8 => uint256) public stakeStatic;
    mapping(uint8 => uint256) public fightRwdStatic;
    uint16 public rwdBurnRate;
    mapping(uint8 => uint32) public staticFightTime;
    mapping(uint8 => uint256) public staticRwdFeeAmount;

    event FightEvent(address indexed user, uint256 nftNo, uint32 rwdTime);
    event ContinueFightEvent(address indexed user, uint256 nftNo, uint32 rwdTime, uint256 preRwd);
    event DrawRewardEvent(address indexed user, uint256 nftNo, uint256 preRwd);
    event ExitFightEvent(address indexed user, uint256 nftNo);

    constructor(
        IData dataObj_,
        IBurnERC20 stakeToken_,
        IBurnERC20 rewardToken_,
        IHeroNFTCard heroCard_,
        IWeaponNFTCard weaponCard_,
        address wGasCoin_
    ){
        dataObj = dataObj_;
        stakeToken = stakeToken_;
        rewardToken = rewardToken_;
        heroCard = heroCard_;
        weaponCard = weaponCard_;
        wGasCoin = wGasCoin_;

        rwdBurnRate = 99;
    }

    receive() external payable {
        assert(msg.sender == wGasCoin);

    }

    function getHeroFightInfo(uint256 _nftNo)
        public view
        returns (uint32, uint256, uint256)
    {
        (uint32 _startT, uint32 _rwdTime, uint256 _reward, uint256 _rewardPreTl, ) = dataObj.heroFightInfo(_nftNo);
        uint256 _curRwd = _reward;
        uint32 _nowts = uint32(block.timestamp);
        if (_nowts < _rwdTime){
            uint32 fightTime = _rwdTime - _startT;
            _curRwd = _reward * (_rwdTime - _nowts) / fightTime;
            _curRwd = _curRwd > _reward ? _reward : _curRwd;
        }
        return (_rwdTime, _reward + _rewardPreTl, _curRwd + _rewardPreTl);
    }

    function getAccFightHeroList(address _acc)
        public view
        returns (uint256[8][] memory _nftsList)
    {
        (uint256[] memory _nftIdList, uint256[4][] memory _infoList) = dataObj.getAccFightHeroInfoList(_acc);
        uint256[2][] memory _slotsList = heroCard.getSlotsList(_nftIdList);
        _nftsList = new uint256[8][](_nftIdList.length);
        for(uint256 i=0;i<_nftsList.length;i++){
            uint256 _feeV = staticRwdFeeAmount[_getHeroNFTLv(_nftIdList[i])];
            _nftsList[i] = [_nftIdList[i], _slotsList[i][0], _slotsList[i][1], _infoList[i][0], _infoList[i][1], _infoList[i][2], _infoList[i][3], _feeV];
        }
    }

    function getAccFightHerosLength(address _acc)
        public view
        returns (uint256)
    {
        return dataObj.accHeroListLength(_acc);
    }

    function getStaticRwdFeeAmount(uint8[] memory _lvList)
        public view
        returns (uint256[] memory _amountList)
    {
        _amountList = new uint256[](_lvList.length);
        for(uint256 i=0;i<_lvList.length;i++){
            _amountList[i] = staticRwdFeeAmount[_lvList[i]];
        }
    }

    function _getHeroNFTLv(uint256 _nftNo)
        private pure
        returns (uint8)
    {
        return uint8((_nftNo >> 16) & (~(~0<<8)));
    }

    function _getStaticFightTime(uint256 _heroNo)
        private view
        returns (uint32)
    {
        uint8 nftLv = _getHeroNFTLv(_heroNo);
        return staticFightTime[nftLv];
    }

    function _getStaticRwdFeeAmount(uint256 _heroNo)
        private view
        returns (uint256)
    {
        uint8 nftLv = _getHeroNFTLv(_heroNo);
        return staticRwdFeeAmount[nftLv];
    }

    function _getFightReward(uint256 _heroNo)
        private view
        returns (uint256)
    {

        uint8 _lv = _getHeroNFTLv(_heroNo);
        uint256 rwdMax =  uint256((fightRwdStatic[_lv] >> 128) & (~(~0<<128)));
        uint256 rwdMin =  uint256(uint128(fightRwdStatic[_lv] & (~(~0<<128))));
        uint256 _rewardV = _getRValue(rwdMax/1e18-rwdMin/1e18)*1e18 + rwdMin;
        uint16 _addR = _getAdditionWithWeapon(_heroNo);
        _rewardV += _rewardV * _addR / 100;
        return _rewardV;
    }

    function _getAdditionWithWeapon(uint256 _heroNo)
        private view
        returns (uint16)
    {
        uint256[2] memory _slotWeapons = heroCard.getNFTSlotWeapons(_heroNo);

        return weaponAddition[uint16(_slotWeapons[0] & (~(~0<<16)))] + weaponAddition[uint16(_slotWeapons[1] & (~(~0<<16)))];
    }

    function getAdditionWithWeapon(uint256 _heroNo)
        public view
        returns (uint16)
    {
        return _getAdditionWithWeapon(_heroNo);
    }

    function _getRValue(uint256 _num)
        private view
        returns (uint32)
    {
        uint256 nowts = block.timestamp + uint256(keccak256(abi.encodePacked(block.coinbase))) / block.timestamp;
        return uint32(
            uint256(keccak256(abi.encodePacked(nowts, block.timestamp, block.difficulty))) % _num
        );
    }

    function _drawReward(uint256 _reward)
        private
        returns (uint256)
    {
        if (_reward > 0){
            uint256 _burnRwd = _reward * rwdBurnRate / 1000;
            rewardToken.safeTransfer(msg.sender, _reward - _burnRwd);
            rewardToken.safeTransfer(address(0x0000000000000000000000000000000000000001), _burnRwd);
            return _reward - _burnRwd;
        }
        return 0;
    }


    function toFighting(uint256 _heroNo)
        public isOpen
    {

        require(heroCard.ownerOf(_heroNo) == msg.sender, "Param error");


        heroCard.safeTransferFrom(msg.sender, address(this), _heroNo);
        uint256 _stakeValue = stakeStatic[_getHeroNFTLv(_heroNo)];
        stakeToken.safeTransferFrom(msg.sender, address(this), _stakeValue);


        uint32 fightTime = _getStaticFightTime(_heroNo);
        uint32 _rwdTime = uint32(block.timestamp + fightTime);
        uint256 _rwdValue = _getFightReward(_heroNo);
        dataObj.addFightHero(msg.sender, _heroNo, _rwdValue, uint32(block.timestamp), _rwdTime);

        emit FightEvent(msg.sender, _heroNo, _rwdTime);
    }


    function continueFighting(uint256 _heroNo)
        public isOpen
    {
        (, uint32 _rwdTime, uint256 _reward, uint256 _rewardPreTl, address _nftFrom) = dataObj.heroFightInfo(_heroNo);
        require(_nftFrom == msg.sender, "Param error");
        require(_rwdTime <= block.timestamp, "It's fighting");


        uint256 _newRwdV = _getFightReward(_heroNo);
        uint32 fightTime = _getStaticFightTime(_heroNo);
        uint32 _newRwdT = uint32(block.timestamp + fightTime);

        dataObj.continueFightHero(_heroNo, _newRwdV, _reward, uint32(block.timestamp), _newRwdT);

        emit ContinueFightEvent(msg.sender, _heroNo, _newRwdT, _rewardPreTl);
    }


    function drawReward(uint256 _heroNo)
        public payable isOpen
    {
        (, uint32 _rwdTime, uint256 _reward, uint256 _rewardPreTl, address _nftFrom) = dataObj.heroFightInfo(_heroNo);
        require(_nftFrom == msg.sender, "Param error");
        require(_rwdTime <= block.timestamp, "It's fighting");
        require (_reward + _rewardPreTl > 0, "Reward zero");


        uint256 _feeAmount = _getStaticRwdFeeAmount(_heroNo);
        if (_feeAmount > 0){
            require(msg.value == _feeAmount, "Pay error");
            IWGasCoin(wGasCoin).deposit{value : _feeAmount}();
        }

        dataObj.clearFightReward(_heroNo);
        uint256 _preRwd = _drawReward(_reward + _rewardPreTl);

        emit DrawRewardEvent(msg.sender, _heroNo, _preRwd);
    }


    function exitFighting(uint256 _heroNo)
        public isOpen
    {
        (, uint32 _rwdTime, uint256 _reward, uint256 _rewardPreTl, address _nftFrom) = dataObj.heroFightInfo(_heroNo);
        require(_nftFrom == msg.sender, "Param error");
        require(_rwdTime <= block.timestamp, "It's fighting");

        require(_reward + _rewardPreTl == 0, "Please draw reward");


        heroCard.safeTransferFrom(address(this), msg.sender, _heroNo);
        uint256 _stakeValue = stakeStatic[_getHeroNFTLv(_heroNo)];
        stakeToken.safeTransfer(msg.sender, _stakeValue);
        dataObj.exitFightHero(msg.sender, _heroNo);

        emit ExitFightEvent(msg.sender, _heroNo);
    }


    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("dataObj")) {
            dataObj = IData(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("stakeToken")) {
            stakeToken = IBurnERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("rewardToken")) {
            rewardToken = IBurnERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("heroCard")) {
            heroCard = IHeroNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("weaponCard")) {
            weaponCard = IWeaponNFTCard(_addr);
        }
    }

    function setStatic(uint256[2][] memory _stakeList, uint256[2][] memory _rwdList, uint16[2][] memory _wpAddiList)
        public onlyAdmin
    {
        for(uint256 i=0;i<_stakeList.length;i++){
            stakeStatic[uint8(_stakeList[i][0])] = _stakeList[i][1];
        }
        for(uint256 i=0;i<_rwdList.length;i++){
            fightRwdStatic[uint8(_rwdList[i][0])] = _rwdList[i][1];
        }
        for(uint256 i=0;i<_wpAddiList.length;i++){
            weaponAddition[_wpAddiList[i][0]] = _wpAddiList[i][1];
        }
    }

    function setRwdBurnRate(uint16 _value)
        public onlyAdmin
    {
        rwdBurnRate = _value;
    }

    function setStaticFightInfo(uint32[2][] memory _timeList, uint256[2][] memory _feeList)
        public onlyAdmin
    {
        for(uint256 i=0;i<_timeList.length;i++){
            staticFightTime[uint8(_timeList[i][0])] = _timeList[i][1];
        }
        for(uint256 i=0;i<_feeList.length;i++){
            staticRwdFeeAmount[uint8(_feeList[i][0])] = _feeList[i][1];
        }
    }

    function transferRewardToken(address addr_, address _token, uint256 amount) external onlyAdmin {
        IBurnERC20(_token).safeTransfer(addr_, amount);
    }

    function transferBatchNFT(address addr_, address _nftCard, uint256[] memory _nftList) external onlyAdmin {
        for(uint256 i=0;i<_nftList.length;i++){
            IERC721(_nftCard).safeTransferFrom(address(this), addr_, _nftList[i]);
        }
    }

}
