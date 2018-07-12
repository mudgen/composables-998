pragma solidity ^0.4.24;

import "./interfaces/ERC998ERC20TopDownI.sol";
import "./ERC998TopDown.sol";
import "./interfaces/ERC20AndERC223.sol";

contract ERC998ERC20TopDown is ERC998TopDown, ERC998ERC20TopDownI {
	  // tokenId => token contract
  mapping(uint256 => address[]) internal erc223Contracts;

  // tokenId => (token contract => token contract index)
  mapping(uint256 => mapping(address => uint256)) internal erc223ContractIndex;
  
  // tokenId => (token contract => balance)
  mapping(uint256 => mapping(address => uint256)) internal erc223Balances;
  
  function balanceOfERC20(uint256 _tokenId, address _erc223Contract) external view returns(uint256) {
    return erc223Balances[_tokenId][_erc223Contract];
  }
  function removeERC223(uint256 _tokenId, address _erc223Contract, uint256 _value) private {
    if(_value == 0) {
      return;
    }
    uint256 erc223Balance = erc223Balances[_tokenId][_erc223Contract];
    require(erc223Balance >= _value, "Not enough token available to transfer.");
    uint256 newERC223Balance = erc223Balance - _value;
    erc223Balances[_tokenId][_erc223Contract] = newERC223Balance;
    if(newERC223Balance == 0) {
      uint256 lastContractIndex = erc223Contracts[_tokenId].length - 1;
      address lastContract = erc223Contracts[_tokenId][lastContractIndex];
      if(_erc223Contract != lastContract) {
        uint256 contractIndex = erc223ContractIndex[_tokenId][_erc223Contract];
        erc223Contracts[_tokenId][contractIndex] = lastContract;
        erc223ContractIndex[_tokenId][lastContract] = contractIndex;
      }
      erc223Contracts[_tokenId].length--;
      delete erc223ContractIndex[_tokenId][_erc223Contract];
    }
  }
  
  
  function transferERC20(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(_to != address(0));
    address rootOwner = ownerOf(_tokenId);
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeERC223(_tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transfer(_to, _value), "ERC20 transfer failed.");
    emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
  }
  
  // implementation of ERC 223
  function transferERC223(uint256 _tokenId, address _to, address _erc223Contract, uint256 _value, bytes _data) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId];
    require(_to != address(0));
    address rootOwner = ownerOf(_tokenId);
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeERC223(_tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transfer(_to, _value, _data), "ERC223 transfer failed.");
    emit TransferERC20(_tokenId, _to, _erc223Contract, _value);
  }

  // this contract has to be approved first by _erc223Contract
  function getERC20(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) public {
    bool allowed = _from == msg.sender;
    if(!allowed) {
      uint256 remaining;
      // 0xdd62ed3e == allowance(address,address)
      bytes memory calldata = abi.encodeWithSelector(0xdd62ed3e,_from,msg.sender);
      bool callSuccess;
      assembly {
        callSuccess := staticcall(gas, _erc223Contract, add(calldata, 0x20), mload(calldata), calldata, 0x20)
        if callSuccess {
          remaining := mload(calldata)
        }
      }
      require(callSuccess, "call to allowance failed");
      require(remaining >= _value, "Value greater than remaining");
      allowed = true;
    }
    require(allowed, "not allowed to getERC20");
    erc223Received(_from, _tokenId, _erc223Contract, _value);
    require(ERC20AndERC223(_erc223Contract).transferFrom(_from, this, _value), "ERC20 transfer failed.");
  }

  function erc223Received(address _from, uint256 _tokenId, address _erc223Contract, uint256 _value) private {
    require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
    if(_value == 0) {
      return;
    }
    uint256 erc223Balance = erc223Balances[_tokenId][_erc223Contract];
    if(erc223Balance == 0) {
      erc223ContractIndex[_tokenId][_erc223Contract] = erc223Contracts[_tokenId].length;
      erc223Contracts[_tokenId].push(_erc223Contract);
    }
    erc223Balances[_tokenId][_erc223Contract] += _value;
    emit ReceivedERC20(_from, _tokenId, _erc223Contract, _value);
  }
  
  // used by ERC 223
  function tokenFallback(address _from, uint256 _value, bytes _data) external {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the token to.");
    require(isContract(msg.sender), "msg.sender is not a contract");
    /**************************************
    * TODO move to library
    **************************************/
    // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
    uint256 tokenId;
    assembly {
      tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
    //END TODO
    erc223Received(_from, tokenId, msg.sender, _value);
  }
}