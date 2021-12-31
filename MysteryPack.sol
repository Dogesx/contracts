//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./owner/SwitchAdmin.sol";

interface IWGasCoin {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IHeroNFTCard {
    function mintNFT(address _to, uint8 _nftLv, uint16 _nftType) external returns (uint256);
}

interface IWeaponNFTCard {
    function mintNFT(address _to, uint8 _nftLv, uint16 _nftType) external returns (uint256);
}

interface IInvRelation {
    function beinvedAddBoxesRwd(address _beinvAcc, uint256 _amount) external;
}

contract MysteryPack is SwitchAdmin {
    using SafeERC20 for IERC20;

    address public immutable wGasCoin;
    IHeroNFTCard public heroCard;
    IWeaponNFTCard public weaponCard;
    IERC20 public rewardToken;
    IERC20 public payToken;
    IInvRelation public invRelationObj;
    address public buyNFTGasDst;

    uint32[2] public packNum;
    uint32 public openedHeroNum;
    uint32 public openedWeaponNum;
    uint32 public accBuyLimit;
    uint256[2] public packPrice;
    uint256[188] public herosPool;
    uint256[625] public weaponsPool;
    mapping(uint16 => uint8) public heroLvStatic;
    mapping(uint16 => uint8) public weaponLvStatic;
    mapping(uint8 => uint256) public heroBoxsRwd;
    mapping(address => uint256) public boxesBuyRwd;
    mapping(address => uint32) public accsBuyHeroNum;


    event OpenHeroPacksEvent(address indexed user, uint256[] nftNoList, uint256[] rwdList);
    event OpenWeaponPacksEvent(address indexed user, uint256[] nftNoList);
    event DrawRewardEvent(address indexed user, uint256 value);

    receive() external payable {
        assert(msg.sender == wGasCoin);

    }

    constructor(IHeroNFTCard heroCard_, IWeaponNFTCard weaponCard_, IInvRelation invRelationObj_, IERC20 rewardToken_, IERC20 payToken_, address wGasCoin_, address buyNFTGasDst_){
        heroCard = heroCard_;
        weaponCard = weaponCard_;
        rewardToken = rewardToken_;
        payToken = payToken_;
        invRelationObj = invRelationObj_;
        wGasCoin = wGasCoin_;
        buyNFTGasDst = buyNFTGasDst_;
        packNum = [3000, 10000];
        packPrice = [4*1e17, 1000*1e18];
        accBuyLimit = 10;
        isPause = 1;
    }

    function getHeroPacksInfo()
        public view
        returns (uint32, uint32, uint32, uint32, uint256)
    {
        return (packNum[0], openedHeroNum, accBuyLimit, accsBuyHeroNum[msg.sender], packPrice[0]);
    }

    function getWeaponPacksInfo()
        public view
        returns (uint32, uint32, uint256)
    {
        return (packNum[1], openedWeaponNum, packPrice[1]);
    }

    function getBoxesBuyRwd(address _acc)
        public view
        returns (uint256)
    {
        return boxesBuyRwd[_acc];
    }

    function openHeroPacks(uint32 _amount)
        public payable isOpen
    {

        require(_amount>0, "Param error");
        require(openedHeroNum + _amount <= packNum[0], "Sold out");
        require(accsBuyHeroNum[msg.sender] + _amount <= accBuyLimit, "Buy limit");


        uint256 _costAmount = packPrice[0] * _amount;
        require(msg.value == _costAmount, "Pay error");
        IWGasCoin(wGasCoin).deposit{value : _costAmount}();
        require(IWGasCoin(wGasCoin).transfer(buyNFTGasDst, _costAmount), "Error");

        uint256[] memory _nftList = new uint256[](_amount);
        uint256[] memory _rwdList = new uint256[](_amount);
        uint256 _boxesRwd = 0;
        for(uint256 i=0;i<_amount;i++){
            uint16 _nftType = uint16((herosPool[(openedHeroNum+i)/16] >> ((openedHeroNum+i)%16*16)) & (~(~0<<16)));
            _nftList[i] = heroCard.mintNFT(msg.sender, heroLvStatic[_nftType], _nftType);
            _boxesRwd += heroBoxsRwd[heroLvStatic[_nftType]];
            _rwdList[i] = heroBoxsRwd[heroLvStatic[_nftType]];
        }


        boxesBuyRwd[msg.sender] += _boxesRwd;
        openedHeroNum += _amount;
        accsBuyHeroNum[msg.sender] += _amount;


        if (address(invRelationObj) != address(0)){
            invRelationObj.beinvedAddBoxesRwd(msg.sender, _boxesRwd);
        }

        emit OpenHeroPacksEvent(msg.sender, _nftList, _rwdList);
    }

    function openWeaponPacks(uint32 _amount)
        public isOpen
    {

        require(_amount>0, "Param error");
        require(openedWeaponNum + _amount <= packNum[1], "Sold out");


        payToken.safeTransferFrom(msg.sender, buyNFTGasDst, packPrice[1] * _amount);

        uint256[] memory _nftList = new uint256[](_amount);
        for(uint256 i=0;i<_amount;i++){
            uint16 _nftType = uint16((weaponsPool[(openedWeaponNum+i)/16] >> ((openedWeaponNum+i)%16*16)) & (~(~0<<16)));
            _nftList[i] = weaponCard.mintNFT(msg.sender, weaponLvStatic[_nftType], _nftType);
        }


        openedWeaponNum += _amount;

        emit OpenWeaponPacksEvent(msg.sender, _nftList);
    }

    function drawReward()
        public isOpen
    {
        require(boxesBuyRwd[msg.sender] > 0, "Reward None");
        uint256 _reward = boxesBuyRwd[msg.sender];

        boxesBuyRwd[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, _reward);

        emit DrawRewardEvent(msg.sender, _reward);
    }


    function setPackNum(uint32 _value, uint8 _idx) public onlyAdmin {
        packNum[_idx] = _value;
    }

    function setOpenedHeroNum(uint32 _value) public onlyAdmin {
        openedHeroNum = _value;
    }

    function setOpenedWeaponNum(uint32 _value) public onlyAdmin {
        openedWeaponNum = _value;
    }

    function setPackPrice(uint256 _value, uint8 _idx) public onlyAdmin {
        packPrice[_idx] = _value;
    }

    function setAccBuyLimit(uint32 _value) public onlyAdmin {
        accBuyLimit = _value;
    }

    function setHerosPool(uint32[] memory _keyList, uint256[] memory _herosPool) public onlyAdmin {
        for (uint256 i = 0; i < _herosPool.length; i++) {
            herosPool[_keyList[i]] = _herosPool[i];
        }
    }

    function setWeaponsPool(uint32[] memory _keyList, uint256[] memory _weaponsPool) public onlyAdmin {
        for (uint256 i = 0; i < _weaponsPool.length; i++) {
            weaponsPool[_keyList[i]] = _weaponsPool[i];
        }
    }

    function setStatic(uint16[2][] memory _heroTypes, uint16[2][] memory _weaponTypes, uint8[] memory _lvList, uint256[] memory _rwdList)
        public onlyAdmin
    {
        for (uint256 i = 0; i < _heroTypes.length; i++) {
            heroLvStatic[_heroTypes[i][0]] = uint8(_heroTypes[i][1]);
        }
        for (uint256 i = 0; i < _weaponTypes.length; i++) {
            weaponLvStatic[_weaponTypes[i][0]] = uint8(_weaponTypes[i][1]);
        }
        for (uint256 i = 0; i < _lvList.length; i++) {
            heroBoxsRwd[_lvList[i]] = _rwdList[i];
        }
    }

    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("rewardToken")) {
            rewardToken = IERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("payToken")) {
            payToken = IERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("heroCard")) {
            heroCard = IHeroNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("weaponCard")) {
            weaponCard = IWeaponNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("invRelationObj")) {
            invRelationObj = IInvRelation(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("buyNFTGasDst")) {
            buyNFTGasDst = _addr;
        }

    }

    function setAccsBuyHeroNum(address _acc, uint32 _value)
        public onlyAdmin
    {
        accsBuyHeroNum[_acc] = _value;
    }

    function setBoxesBuyRwd(address _acc, uint256 _value)
        public onlyAdmin
    {
        boxesBuyRwd[_acc] = _value;
    }

    function addBoxesBuyRwd(address _acc, uint256 _value)
        public onlyAdmin
    {
        boxesBuyRwd[_acc] += _value;
    }

    function subBoxesBuyRwd(address _acc, uint256 _value)
        public onlyAdmin
    {
        boxesBuyRwd[_acc] -= _value;
    }

    function transferRewardToken(address addr_, address _token, uint256 amount) external onlyAdmin {
        IERC20(_token).safeTransfer(addr_, amount);
    }

}
