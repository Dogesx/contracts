//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../owner/SwitchAdmin.sol";

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IData {
    function addAccWeapon(address _acc, uint256 _nftNo) external;
    function removeAccWeapon(address _acc, uint256 _nftNo) external;
}

interface IHeroNFTCard {
    function getNFTInfo(uint256 _nftNo) external view returns (uint8 _nftDur, address _acc, uint256[2] memory _slots);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
    function addSlot(uint256 _nftNo, uint256 _slotNftId, uint256 _slotPos) external;
    function removeSlot(uint256 _nftNo, uint256 _slotPos) external;
    function mintNFT(address _to, uint8 _nftLv, uint16 _nftType) external returns (uint256);
}

interface IWeaponNFTCard {
    function getNFTInfo(uint256 _nftNo) external view returns (uint8 _nftDur, address _acc, uint256 _hecoId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function addSlot(uint256 _nftNo, uint256 _heroNFTId) external;
    function removeSlot(uint256 _nftNo) external;
}

interface IRandom {
    function getRandomHInt() external returns (uint16 value);
}

contract GNFTOption is SwitchAdmin, ERC721Holder {
    using SafeERC20 for IERC20;

    IData public dataObj;
    IHeroNFTCard public heroCard;
    IWeaponNFTCard public weaponCard;
    IRandom public randomObj;

    uint8 public compoundLength;

    mapping(uint8 => uint256) public compoundNFTNums;
    mapping(uint8 => uint256) public compoundStatic;
    mapping(uint8 => uint8) public compoundProb;

    event LoadingSlotsNFTEvent(address indexed user, uint256 heroNo, uint256 weaponNo, uint256 slotNo);
    event CompoundNFTEvent(address indexed user, uint256 nftNo, uint256[] cnftList);

    constructor(IData dataObj_, IHeroNFTCard heroCard_, IWeaponNFTCard weaponCard_, IRandom randomObj_){
        dataObj = dataObj_;
        heroCard = heroCard_;
        weaponCard = weaponCard_;
        randomObj = randomObj_;

        compoundLength = 2;
    }

    function loadingSlots(uint256 _heroNFTNo, uint256 _weaponNFTNo, uint256 _slotNo)
        public isOpen
    {
        require (_slotNo <= 1, "Param error");

        (, address _heroAcc, uint256[2] memory _slotWps) = heroCard.getNFTInfo(_heroNFTNo);
        require (_heroAcc == msg.sender, "HeroNFT tokenId error");
        require (_slotWps[_slotNo] != _weaponNFTNo, "There is no change");

        if (_weaponNFTNo > 0){
            (, address _wpAcc, uint256 _hecoId) = weaponCard.getNFTInfo(_weaponNFTNo);
            require (_wpAcc == msg.sender && _hecoId == 0, "WeaponNFT tokenId error");

            if (_slotWps[_slotNo] > 0) {
                weaponCard.removeSlot(_slotWps[_slotNo]);
                dataObj.removeAccWeapon(msg.sender, _slotWps[_slotNo]);
                weaponCard.safeTransferFrom(address(this), msg.sender, _slotWps[_slotNo]);
            }

            weaponCard.addSlot(_weaponNFTNo, _heroNFTNo);
            heroCard.addSlot(_heroNFTNo, _weaponNFTNo, _slotNo);
            dataObj.addAccWeapon(msg.sender, _slotWps[_slotNo]);
            weaponCard.safeTransferFrom(msg.sender, address(this), _weaponNFTNo);
        } else {

            weaponCard.removeSlot(_slotWps[_slotNo]);
            heroCard.removeSlot(_heroNFTNo, _slotNo);
            dataObj.removeAccWeapon(msg.sender, _slotWps[_slotNo]);
            weaponCard.safeTransferFrom(address(this), msg.sender, _slotWps[_slotNo]);
        }

        emit LoadingSlotsNFTEvent(msg.sender, _heroNFTNo, _weaponNFTNo, _slotNo);
    }

    function getCompoundStatic(uint256 _value)
        public pure
        returns (uint16[] memory _nftTypes, uint8 _typeNum)
    {

        _typeNum = uint8(_value & (~(~0<<8)));
        _nftTypes = new uint16[](_typeNum);
        for(uint256 i=0;i<_typeNum;i++){
            _nftTypes[i] = uint16((_value >> (8+i*16)) & (~(~0<<16)));
        }
    }


    function compoundNFT(uint256[] memory _cnftList)
        public isOpen
    {
        require(_cnftList.length == compoundLength, "Param length error");
        uint8 _cnftLv = 0;
        for(uint256 i=0;i<_cnftList.length;i++){
            (, address _heroAcc, uint256[2] memory _slotWps) = heroCard.getNFTInfo(_cnftList[i]);
            require (_heroAcc == msg.sender, "HeroNFT tokenId error");
            require (_slotWps[0] + _slotWps[1] == 0, "Can't compound with weapon");
            if (_cnftLv == 0) {
                _cnftLv = uint8((_cnftList[i] >> 16) & (~(~0<<8))) + 1;
            } else {
                require (_cnftLv == uint8((_cnftList[i] >> 16) & (~(~0<<8))) + 1, "NFT level error");
            }
        }




        for(uint256 i=0;i<_cnftList.length;i++){
            heroCard.burn(_cnftList[i]);
        }


        uint256 newNFTNo = 0;
        uint16 _prob = randomObj.getRandomHInt();
        if (_prob <= compoundProb[_cnftLv]){

            compoundNFTNums[_cnftLv] += 1;
            uint8 _cnum = uint8(compoundStatic[_cnftLv] & (~(~0<<8)));
            uint16 _nftType = uint16((compoundStatic[_cnftLv] >> (8+compoundNFTNums[_cnftLv]%_cnum*16)) & (~(~0<<16)));
            newNFTNo = heroCard.mintNFT(msg.sender, _cnftLv, _nftType);
        }

        emit CompoundNFTEvent(msg.sender, newNFTNo, _cnftList);
    }


    function setCompoundStatic(uint256[4][] memory _staticList, uint8[2][] memory _probList)
        public onlyAdmin
    {
        for(uint256 i=0;i<_staticList.length;i++){
            compoundStatic[uint8(_staticList[i][0])] = uint256((_staticList[i][2] << 8) + _staticList[i][3]);
        }
        for(uint256 i=0;i<_probList.length;i++){
            compoundProb[_probList[i][0]] = _probList[i][1];
        }

    }

    function setCompoundLength(uint8 _value)
        public onlyAdmin
    {
        compoundLength = _value;
    }

    function setAddrObj(address _addr, string memory _key)
        public onlyAdmin
    {
        if (keccak256(bytes(_key)) == keccak256("dataObj")) {
            dataObj = IData(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("heroCard")) {
            heroCard = IHeroNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("weaponCard")) {
            weaponCard = IWeaponNFTCard(_addr);
        } else if (keccak256(bytes(_key)) == keccak256("randomObj")) {
            randomObj = IRandom(_addr);
        }
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
