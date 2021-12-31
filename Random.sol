//SPDX-License-Identifier: MIT
pragma solidity >=0.8.3 <0.9.0;

import "./owner/AdminRole.sol";


contract Random is AdminRole {
    uint32 public randomNo;
    mapping(uint32 => uint256) randomPool;
    uint32 public randomPoolSize;


    constructor(){
        randomPoolSize = 32 * 1000;
    }

    function getRandomRangeInt(uint16 _leftV, uint16 _rightV)
        public onlyAdmin
        returns (uint16 value)
    {
        require(_rightV > _leftV, "Param error");
        value = uint16(uint32(_opRandomInt())*(_rightV-_leftV+1)/10000+_leftV);
    }

    function getRandomHInt()
        public onlyAdmin
        returns (uint16 value)
    {
        value = _opRandomInt()/100+1;
    }

    function getRandomKInt()
        public onlyAdmin
        returns (uint16 value)
    {
        value = _opRandomInt()/10+1;
    }

    function getRandomWInt()
        public onlyAdmin
        returns (uint16 value)
    {
        value = _opRandomInt()+1;
    }

    function getRandomMultiHInt(uint32 _num)
        public onlyAdmin
        returns (uint16[] memory valueList)
    {
        require(_num > 0, "Param error");
        valueList = _opRandomMultiInt(_num, 100);
    }

    function getRandomMultiKInt(uint32 _num)
        public onlyAdmin
        returns (uint16[] memory valueList)
    {
        require(_num > 0, "Param error");
        valueList = _opRandomMultiInt(_num, 10);
    }

    function getRandomMultiWInt(uint32 _num)
        public onlyAdmin
        returns (uint16[] memory valueList)
    {
        require(_num > 0, "Param error");
        valueList = _opRandomMultiInt(_num, 1);
    }

    function _opRandomInt()
        private
        returns (uint16)
    {
        randomNo = (randomNo+1)%randomPoolSize;
        return _getRandomValue(randomNo);
    }

    function _opRandomMultiInt(uint32 _num, uint16 _keyV)
        private
        returns (uint16[] memory valueList)
    {
        randomNo = (randomNo+1)%randomPoolSize;
        valueList = new uint16[](_num);
        valueList[0] = _getRandomValue(randomNo)/_keyV+1;
        uint32 _eprV = _getEncodeRandomV(100);
        for(uint32 i=2;i<=_num;i++){
            valueList[i-1] = _getRandomValue((randomNo+randomPoolSize/2+i*_eprV)%randomPoolSize)/_keyV+1;
        }
    }

    function _getRandomValue(uint32 _rNo)
        private view
        returns (uint16)
    {
        return uint16((randomPool[_rNo/16] >> ((_rNo % 16) * 16)) & (~(~0<<16)));
    }

    function _getEncodeRandomV(uint256 _num)
        private view
        returns (uint32)
    {
        uint256 nowts = block.timestamp + uint256(keccak256(abi.encodePacked(block.coinbase))) / block.timestamp + randomNo;
        return uint32(
            uint256(keccak256(abi.encodePacked(nowts, block.timestamp, block.difficulty))) % _num
        );
    }

    function getRandomValue(uint32 _rNo)
        public view onlyAdmin
        returns (uint16)
    {
        return _getRandomValue(_rNo%randomPoolSize);
    }

    function setRandomNo(uint32 _value) public onlyAdmin{
        randomNo = _value;
    }

    function setRandomPoolSize(uint32 _value) public onlyAdmin{
        randomPoolSize = _value;
    }

    function setRandomPool(uint32[] memory _keyList, uint256[] memory _valueList) public onlyAdmin {
        for(uint256 i=0;i<_keyList.length;i++){
            randomPool[_keyList[i]] = _valueList[i];
        }
    }
}
