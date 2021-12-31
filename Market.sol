//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./owner/SwitchAdmin.sol";

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IData {
    function getSellHeroInfo(uint256 _nftNo) external view returns (bool, uint256, address);
    function getAccSoldHeroRecords(address _acc, uint256 _startIdx, uint256 _endIdx) external view returns (uint256[2][] memory _records);
    function getAccSellHeroList(address _acc) external view returns (uint256[2][] memory _nftList);
    function getAllSellHeroList(uint256 _startIdx, uint256 _endIdx) external view returns (uint256[2][] memory _nftList);
    function allHerosLength() external view returns (uint256);

    function addSellHero(address _acc, uint256 _nftNo, uint256 _price) external;
    function cancelSellHero(address _acc, uint256 _nftNo) external;
    function buySellHero(uint256 _nftNo) external;

    function getSellWeaponInfo(uint256 _nftNo) external view returns (bool, uint256, address);
    function getAccSoldWeaponRecords(address _acc, uint256 _startIdx, uint256 _endIdx) external view returns (uint256[2][] memory _records);
    function getAccSellWeaponList(address _acc) external view returns (uint256[2][] memory _nftList);
    function getAllSellWeaponList(uint256 _startIdx, uint256 _endIdx) external view returns (uint256[2][] memory _nftList);
    function allWeaponsLength() external view returns (uint256);

    function addSellWeapon(address _acc, uint256 _nftNo, uint256 _price) external;
    function cancelSellWeapon(address _acc, uint256 _nftNo) external;
    function buySellWeapon(uint256 _nftNo) external;

}

interface IHeroNFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);
    function getNFTInfo(uint256 _nftNo) external view returns (uint8 _nftDur, address _acc, uint256[2] memory _slots);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IWeaponNFTCard {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isExists(uint256 _nftNo) external view returns (uint8);
    function getNFTInfo(uint256 _nftNo) external view returns (uint8 _nftDur, address _acc, uint256 _hecoId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract Market is SwitchAdmin, ERC721Holder {
    using SafeERC20 for IERC20;

    IData public dataObj;
    IERC20 public payToken;
    IHeroNFTCard public heroCard;
    IWeaponNFTCard public weaponCard;

    address public feeAddr;

    uint32 public sellFeeRate;

    event SellHeroEvent(address indexed user, uint256 nftNo, uint256 price);
    event CancelSellHeroEvent(address indexed user, uint256 nftNo);
    event BuyHeroEvent(address indexed user, uint256 nftNo);
    event SellWeaponEvent(address indexed user, uint256 nftNo, uint256 price);
    event CancelSellWeaponEvent(address indexed user, uint256 nftNo);
    event BuyWeaponEvent(address indexed user, uint256 nftNo);

    constructor(
        IData dataObj_,
        IERC20 payToken_,
        IHeroNFTCard heroCard_,
        IWeaponNFTCard weaponCard_,
        address feeAddr_
    ){
        dataObj = dataObj_;
        payToken = payToken_;
        heroCard = heroCard_;
        weaponCard = weaponCard_;
        feeAddr = feeAddr_;

        sellFeeRate = 6;
    }

    function getSoldHeroRecords(address _acc)
        public view
        returns (uint256[2][] memory _records)
    {
        return dataObj.getAccSoldHeroRecords(_acc, 0, 50);
    }

    function getAccSellHeroList(address _acc)
        public view
        returns (uint256[2][] memory _nftsList)
    {
        _nftsList = dataObj.getAccSellHeroList(_acc);
    }

    function getAllSellHeroList(uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _nftList)
    {
        _nftList = dataObj.getAllSellHeroList(_startIdx, _endIdx);
    }

    function getAllSellHerosLength()
        public view
        returns (uint256)
    {
        return dataObj.allHerosLength();
    }

    function getSoldWeaponRecords(address _acc)
        public view
        returns (uint256[2][] memory _records)
    {
        return dataObj.getAccSoldWeaponRecords(_acc, 0, 50);
    }

    function getAccSellWeaponList(address _acc)
        public view
        returns (uint256[2][] memory _nftList)
    {
        _nftList = dataObj.getAccSellWeaponList(_acc);
    }

    function getAllSellWeaponList(uint256 _startIdx, uint256 _endIdx)
        public view
        returns (uint256[2][] memory _nftList)
    {
        _nftList = dataObj.getAllSellWeaponList(_startIdx, _endIdx);
    }

    function getAllSellWeaponsLength()
        public view
        returns (uint256)
    {
        return dataObj.allWeaponsLength();
    }

    function sellHero(uint256 _nftNo, uint256 _price)
        public isOpen
    {
        require(_price > 0, "Price error");
        (, address _heroAcc, uint256[2] memory _slotWps) = heroCard.getNFTInfo(_nftNo);

        require (_heroAcc == msg.sender, "HeroNFT tokenId error");
        require (_slotWps[0] + _slotWps[1] == 0, "Can't operate with weapon");

        dataObj.addSellHero(msg.sender, _nftNo, _price);

        heroCard.safeTransferFrom(msg.sender, address(this), _nftNo);

        emit SellHeroEvent(msg.sender, _nftNo, _price);
    }

    function cancelSellHero(uint256 _nftNo)
        public isOpen
    {
        (bool _exist, , address _nftFrom) = dataObj.getSellHeroInfo(_nftNo);
        require(_exist && _nftFrom == msg.sender, "Param error");

        dataObj.cancelSellHero(msg.sender, _nftNo);
        heroCard.safeTransferFrom(address(this), msg.sender, _nftNo);

        emit CancelSellHeroEvent(msg.sender, _nftNo);
    }

    function buyHero(uint256 _nftNo)
        public isOpen
    {
        (bool _exist, uint256 _price, address _nftFrom) = dataObj.getSellHeroInfo(_nftNo);
        require(_exist, "It's sold out");
        require(_nftFrom != msg.sender, "It's yours");

        dataObj.buySellHero(_nftNo);

        uint256 _feeV = _price * sellFeeRate / 100;
        payToken.safeTransferFrom(msg.sender, feeAddr, _feeV);
        payToken.safeTransferFrom(msg.sender, _nftFrom, _price-_feeV);


        heroCard.safeTransferFrom(address(this), msg.sender, _nftNo);

        emit BuyHeroEvent(msg.sender, _nftNo);
    }

    function sellWeapon(uint256 _nftNo, uint256 _price)
        public isOpen
    {
        require(weaponCard.ownerOf(_nftNo) == msg.sender, "Param error");
        require(_price > 0, "Price error");

        (, address _wpAcc, uint256 _hecoId) = weaponCard.getNFTInfo(_nftNo);
        require (_wpAcc == msg.sender, "WeaponNFT tokenId error");
        require (_hecoId == 0, "It's loading");

        dataObj.addSellWeapon(msg.sender, _nftNo, _price);

        weaponCard.safeTransferFrom(msg.sender, address(this), _nftNo);

        emit SellWeaponEvent(msg.sender, _nftNo, _price);
    }

    function cancelSellWeapon(uint256 _nftNo)
        public isOpen
    {
        (bool _exist, , address _nftFrom) = dataObj.getSellWeaponInfo(_nftNo);
        require(_exist && _nftFrom == msg.sender, "Param error");

        dataObj.cancelSellWeapon(msg.sender, _nftNo);
        weaponCard.safeTransferFrom(address(this), msg.sender, _nftNo);

        emit CancelSellWeaponEvent(msg.sender, _nftNo);
    }

    function buyWeapon(uint256 _nftNo)
        public isOpen
    {
        (bool _exist, uint256 _price, address _nftFrom) = dataObj.getSellWeaponInfo(_nftNo);
        require(_exist && _nftFrom != msg.sender, "Param error");

        dataObj.buySellWeapon(_nftNo);

        uint256 _feeV = _price * sellFeeRate / 100;
        payToken.safeTransferFrom(msg.sender, feeAddr, _feeV);
        payToken.safeTransferFrom(msg.sender, _nftFrom, _price-_feeV);


        weaponCard.safeTransferFrom(address(this), msg.sender, _nftNo);

        emit BuyWeaponEvent(msg.sender, _nftNo);
    }


    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("dataObj")) {
            dataObj = IData(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("payToken")) {
            payToken = IERC20(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("heroCard")) {
            heroCard = IHeroNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("weaponCard")) {
            weaponCard = IWeaponNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("feeAddr")) {
            feeAddr = _addr;
        }
    }

    function setSellFeeRate(uint32 _value) public onlyAdmin {
        sellFeeRate = _value;
    }

    function transferRewardToken(address addr_, address _token, uint256 amount) external onlyAdmin {
        IERC20(_token).safeTransfer(addr_, amount);
    }

    function transferBatchNFT(address addr_, address _nftCard, uint256[] memory _nftList) external onlyAdmin {
        for(uint256 i=0;i<_nftList.length;i++){
            IERC721(_nftCard).safeTransferFrom(address(this), addr_, _nftList[i]);
        }
    }

}
