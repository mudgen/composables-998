pragma solidity ^0.4.24;

import "./interfaces/ERC998ERC721TopDownI.sol";
import "./ERC998TopDown.sol";
import 'zeppelin-solidity/contracts/token/ERC721/ERC721.sol';

contract ERC998ERC721TopDown is ERC998ERC721TopDownI, ERC998TopDown {
  // tokenId => child contract
  mapping(uint256 => address[]) internal childContracts;

  // tokenId => (child address => contract index+1)
  mapping(uint256 => mapping(address => uint256)) internal childContractIndex;

  // tokenId => (child address => array of child tokens)
  mapping(uint256 => mapping(address => uint256[])) internal childTokens;

  function onERC721Received(address _from, uint256 _childTokenId, bytes _data) external returns(bytes4) {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
    require(isContract(msg.sender), "msg.sender is not a contract.");
    /**************************************
    * TODO move to library
    **************************************/
    // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
    uint256 tokenId;
    assembly {
    // new onERC721Received
      //tokenId := calldataload(164)
      tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
    //END TODO

    //require(this == ERC721Basic(msg.sender).ownerOf(_childTokenId), "This contract does not own the child token.");

    receiveChild(_from, tokenId, msg.sender, _childTokenId);
    //cause out of gas error if circular ownership
    ownerOf(tokenId);
    return ERC721_RECEIVED_OLD;
  }


  function onERC721Received(address _operator, address _from, uint256 _childTokenId, bytes _data) external returns(bytes4) {
    require(_data.length > 0, "_data must contain the uint256 tokenId to transfer the child token to.");
    require(isContract(msg.sender), "msg.sender is not a contract.");
    /**************************************
    * TODO move to library
    **************************************/
    // convert up to 32 bytes of_data to uint256, owner nft tokenId passed as uint in bytes
    uint256 tokenId;
    assembly {
      // new onERC721Received
      tokenId := calldataload(164)
      //tokenId := calldataload(132)
    }
    if(_data.length < 32) {
      tokenId = tokenId >> 256 - _data.length * 8;
    }
    //END TODO

    //require(this == ERC721Basic(msg.sender).ownerOf(_childTokenId), "This contract does not own the child token.");

    receiveChild(_from, tokenId, msg.sender, _childTokenId);
    //cause out of gas error if circular ownership
    ownerOf(tokenId);
    return ERC721_RECEIVED_NEW;
  }

  
  function onERC998Removed(uint256 _childTokenId) external {
    uint256 tokenId = childTokenOwner[msg.sender][_childTokenId];
    removeChild(tokenId, msg.sender, _childTokenId);
  }


  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId) external {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = ownerOf(tokenId);
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeChild(tokenId, _childContract, _childTokenId);
    ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  function safeTransferChild(address _to, address _childContract, uint256 _childTokenId, bytes _data) external {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = ownerOf(tokenId);
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeChild(tokenId, _childContract, _childTokenId);
    ERC721(_childContract).safeTransferFrom(this, _to, _childTokenId, _data);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  function transferChild(address _to, address _childContract, uint256 _childTokenId) external {
    (uint256 tokenId, uint256 isParent) = ownerOfChild(_childContract, _childTokenId);
    require(uint8(isParent) > 0);
    address tokenOwner = tokenIdToTokenOwner[tokenId];
    require(_to != address(0));
    address rootOwner = ownerOf(tokenId);
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);
    removeChild(tokenId, _childContract, _childTokenId);
    //this is here to be compatible with cryptokitties and other old contracts that require being owner and approved
    // before transferring.
    //does not work with current standard which does not allow approving self, so we must let it fail in that case.
    //0x095ea7b3 == "approve(address,uint256)"
    bytes memory calldata = abi.encodeWithSelector(0x095ea7b3, this, _childTokenId);
    assembly {
      let success := call(gas, _childContract, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
    }
    ERC721(_childContract).transferFrom(this, _to, _childTokenId);
    emit TransferChild(tokenId, _to, _childContract, _childTokenId);
  }

  // this contract has to be approved first in _childContract
  function getChild(address _from, uint256 _tokenId, address _childContract, uint256 _childTokenId) external {
    receiveChild(_from, _tokenId, _childContract, _childTokenId);
    require(_from == msg.sender ||
      ERC721(_childContract).isApprovedForAll(_from, msg.sender) ||
      ERC721(_childContract).getApproved(_childTokenId) == msg.sender);
    ERC721(_childContract).transferFrom(_from, this, _childTokenId);
    //cause out of gas error if circular ownership
    ownerOf(_tokenId);
  }

  function removeChild(uint256 _tokenId, address _childContract, uint256 _childTokenId) private {
    uint256 tokenIndex = childTokenIndex[_tokenId][_childContract][_childTokenId];
    require(tokenIndex != 0, "Child token not owned by token.");

    // remove child token
    uint256 lastTokenIndex = childTokens[_tokenId][_childContract].length-1;
    uint256 lastToken = childTokens[_tokenId][_childContract][lastTokenIndex];
    if(_childTokenId == lastToken) {
      childTokens[_tokenId][_childContract][tokenIndex-1] = lastToken;
      childTokenIndex[_tokenId][_childContract][lastToken] = tokenIndex;
    }
    childTokens[_tokenId][_childContract].length--;
    delete childTokenIndex[_tokenId][_childContract][_childTokenId];
    delete childTokenOwner[_childContract][_childTokenId];

    // remove contract
    if(lastTokenIndex == 0) {
      uint256 lastContractIndex = childContracts[_tokenId].length - 1;
      address lastContract = childContracts[_tokenId][lastContractIndex];
      if(_childContract != lastContract) {
        uint256 contractIndex = childContractIndex[_tokenId][_childContract];
        childContracts[_tokenId][contractIndex] = lastContract;
        childContractIndex[_tokenId][lastContract] = contractIndex;
      }
      childContracts[_tokenId].length--;
      delete childContractIndex[_tokenId][_childContract];
    }
  }

  function receiveChild(address _from,  uint256 _tokenId, address _childContract, uint256 _childTokenId) private {
    require(tokenIdToTokenOwner[_tokenId] != address(0), "_tokenId does not exist.");
    require(childTokenIndex[_tokenId][_childContract][_childTokenId] == 0, "Cannot receive child token because it has already been received.");
    uint256 childTokensLength = childTokens[_tokenId][_childContract].length;
    if(childTokensLength == 0) {
      childContractIndex[_tokenId][_childContract] = childContracts[_tokenId].length;
      childContracts[_tokenId].push(_childContract);
    }
    childTokens[_tokenId][_childContract].push(_childTokenId);
    childTokenIndex[_tokenId][_childContract][_childTokenId] = childTokensLength + 1;
    childTokenOwner[_childContract][_childTokenId] = _tokenId;
    emit ReceivedChild(_from, _tokenId, _childContract, _childTokenId);
  }
}