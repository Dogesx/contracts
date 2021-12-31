//SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../owner/AdminRole.sol";


contract WeaponNFT is ERC721Burnable, AdminRole {
    using EnumerableSet for EnumerableSet.UintSet;

    uint8 public constant durableMax = 100;
    mapping(address => EnumerableSet.UintSet) ownerNFTs;
    mapping(uint256 => uint8) public nftsDurExpend;
    mapping(uint256 => uint256) public slotHero;

    uint256 public nftNumber = 10000;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == to) { return; }
        ownerNFTs[from].remove(tokenId);
        ownerNFTs[to].add(tokenId);
    }

    function getOwnerNFTList(address _acc)
        public view
        returns (uint256[] memory _nftList)
    {
        _nftList = new uint256[](ownerNFTs[_acc].length());
        for(uint256 i=0;i<_nftList.length;i++){
            _nftList[i] = ownerNFTs[_acc].at(i);
        }
    }

    function getOwnerNFTRangeInfo(address _acc, uint256 _startNo, uint256 _endNo)
        public view
        returns (uint256[2][] memory _nftList)
    {
        if (_startNo >= ownerNFTs[_acc].length()){
            _endNo = _startNo;
        } else if (_endNo > ownerNFTs[_acc].length()) {
            _endNo = ownerNFTs[_acc].length();
        }
        _nftList = new uint256[2][](_endNo - _startNo);
        for(uint256 i=0;i<_nftList.length;i++){
            uint256 _nftNo = ownerNFTs[_acc].at(i+_startNo);
            _nftList[i] = [_nftNo, slotHero[_nftNo]];
        }
    }

    function getOwnerNFTRange(address _acc, uint256 _startNo, uint256 _endNo)
        public view
        returns (uint256[] memory _nftList)
    {
        if (_startNo >= ownerNFTs[_acc].length()){
            _endNo = _startNo;
        } else if (_endNo > ownerNFTs[_acc].length()) {
            _endNo = ownerNFTs[_acc].length();
        }
        _nftList = new uint256[](_endNo - _startNo);
        for(uint256 i=0;i<_nftList.length;i++){
            _nftList[i] = ownerNFTs[_acc].at(i + _startNo);
        }
    }

    function getOwnerNFTToLoadRange(address _acc, uint256 _startNo, uint256 _endNo)
        public view
        returns (uint256[] memory _nftList)
    {
        if (_startNo >= ownerNFTs[_acc].length()){
            _endNo = _startNo;
        } else if (_endNo > ownerNFTs[_acc].length()) {
            _endNo = ownerNFTs[_acc].length();
        }
        uint256[] memory _nftAll = new uint256[](_endNo - _startNo);
        uint256 _cLength = 0;
        for(uint256 i=0;i<_nftAll.length;i++){
            uint256 _nftNo = ownerNFTs[_acc].at(i + _startNo);
            if (slotHero[_nftNo] == 0) {
                _nftAll[_cLength] = _nftNo;
                _cLength += 1;
            }
        }
        _nftList = new uint256[](_cLength);
        for(uint256 i=0;i<_cLength;i++){
            _nftList[i] = _nftAll[i];
        }
    }

    function ownerNFTsContains(address _acc, uint256 _nftNo)
        public view onlyAdmin
        returns (bool)
    {
        return ownerNFTs[_acc].contains(_nftNo);
    }

    function ownerNFTsAt(address _acc, uint256 _index)
        public view onlyAdmin
        returns (uint256)
    {
        return ownerNFTs[_acc].at(_index);
    }

    function ownerNFTsLength(address _acc)
        public view onlyAdmin
        returns (uint256)
    {
        return ownerNFTs[_acc].length();
    }

    function isExists(uint256 _nftNo)
        public view
        returns (bool)
    {
        return _exists(_nftNo);
    }

    function getNFTInfo(uint256 _nftNo)
        public view
        returns (uint8 _nftDur, address _acc, uint256 _hecoId)
    {
        _nftDur = durableMax - nftsDurExpend[_nftNo];
        _acc = ownerOf(_nftNo);
        _hecoId = slotHero[_nftNo];
    }

    function getNFTSlotHero(uint256 _nftNo)
        public view
        returns (uint256)
    {
        return slotHero[_nftNo];
    }

    function getNFTProps(uint256 _nftNo)
        public view
        returns (uint8 _lv, uint16 _class, uint256 _hecoId)
    {
        _lv = uint8((_nftNo >> 16) & (~(~0<<8)));
        _class = uint16(_nftNo & (~(~0<<16)));
        _hecoId = slotHero[_nftNo];
    }

    function getNFTDurable(uint256 _nftNo)
        public view
        returns (uint8)
    {
        return durableMax - nftsDurExpend[_nftNo];
    }

    function ownerOfList(uint256[] memory _nftList)
        public view
        returns(address[] memory _addrsList)
    {
        _addrsList = new address[](_nftList.length);
        for(uint256 i=0;i<_nftList.length;i++){
            _addrsList[i] = ownerOf(_nftList[i]);
        }
    }

    function _getNFTNo(uint256 _num, uint8 _nftLv, uint16 _nftType)
        private view
        returns (uint256)
    {
        return uint256((_num << 192) + (block.timestamp << 128) + (uint256(1) << 64) + (uint256(_nftLv) << 16) + _nftType);
    }

    function mintNFT(address _to, uint8 _nftLv, uint16 _nftType)
        public onlyAdmin
        returns (uint256)
    {
        nftNumber++;
        uint256 nftNo = _getNFTNo(nftNumber, _nftLv, _nftType);
        _safeMint(_to, nftNo);
        return nftNo;
    }

    function addSlot(uint256 _nftNo, uint256 _heroNFTId)
        public onlyAdmin
    {
        slotHero[_nftNo] = _heroNFTId;
    }

    function removeSlot(uint256 _nftNo)
        public onlyAdmin
    {
        slotHero[_nftNo] = 0;
    }

    function recoverDurable(uint256 _nftNo)
        public onlyAdmin
    {
        nftsDurExpend[_nftNo] = 0;
    }

    function setNFTNumber(uint256 _no)
        public onlyAdmin
    {
        nftNumber = _no;
    }

    function addNFTDurable(uint256 _nftNo, uint8 _value)
        public onlyAdmin
    {
        require(nftsDurExpend[_nftNo] >= _value, "Durable is too large");
        nftsDurExpend[_nftNo] -= _value;
    }

    function subNFTDurable(uint256 _nftNo, uint8 _value)
        public onlyAdmin
    {
        require(nftsDurExpend[_nftNo] + _value <= durableMax, "Durable is too small");
        nftsDurExpend[_nftNo] += _value;
        if (nftsDurExpend[_nftNo] + _value > durableMax) {
            nftsDurExpend[_nftNo] = durableMax;
        } else {
            nftsDurExpend[_nftNo] += _value;
        }
    }

}
