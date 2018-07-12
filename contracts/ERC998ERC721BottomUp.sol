pragma solidity ^0.4.24;

import "./interfaces/ERC998ERC721BottomUpI.sol";
import "./ERC998BottomUp.sol";
import 'zeppelin-solidity/contracts/token/ERC721/ERC721.sol';
import "./interfaces/ERC998.sol";

contract ERC998ERC721BottomUp is ERC998ERC721BottomUpI, ERC998BottomUp{

  function transferFromParent(address _fromContract, uint256 _fromTokenId, address _to, uint256 _tokenId, bytes _data) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
    require(tokenOwner == _fromContract);
    require(_to != address(0));
    uint256 parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
    require(parentTokenId != 0, "Token does not have a parent token.");
    require(parentTokenId-1 == _fromTokenId);
    address rootOwner = ownerOf(_tokenId);
    address approvedAddress = rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] || approvedAddress == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);

    // clear approval
    if(approvedAddress != address(0)) {
      delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    // remove and transfer token
    if(_fromContract != _to) {
      assert(tokenOwnerToTokenCount[_fromContract] > 0);
      tokenOwnerToTokenCount[_fromContract]--;
      tokenOwnerToTokenCount[_to]++;
    }

    tokenIdToTokenOwner[_tokenId].tokenOwner = _to;
    tokenIdToTokenOwner[_tokenId].parentTokenId = 0;

    removeChild(_fromContract, _fromTokenId,_tokenId);
    delete tokenIdToChildTokenIdsIndex[_tokenId];

    if(isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _fromContract, _tokenId, _data);
      require(retval == ERC721_RECEIVED);
    }

    emit Transfer(_fromContract, _to, _tokenId);
    emit TransferFromParent(_fromContract, _fromTokenId, _tokenId);

  }

  function transferToParent(address _from, address _toContract, uint256 _toTokenId, uint256 _tokenId) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
    require(tokenOwner == _from);
    require(_toContract != address(0));
    require(tokenIdToTokenOwner[_tokenId].parentTokenId == 0, "Cannot transfer from address when owned by a token.");
    address rootOwner = ownerOf(_tokenId);
    address approvedAddress = rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] || approvedAddress == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);

    // clear approval
    if(approvedAddress != address(0)) {
      delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    // remove and transfer token
    if(_from != _toContract) {
      assert(tokenOwnerToTokenCount[_from] > 0);
      tokenOwnerToTokenCount[_from]--;
      tokenOwnerToTokenCount[_toContract]++;
    }
    TokenOwner memory parentToken = TokenOwner(_toContract, _toTokenId.add(1));
    tokenIdToTokenOwner[_tokenId] = parentToken;
    uint256 index = parentToChildTokenIds[_toContract][_toTokenId].length;
    parentToChildTokenIds[_toContract][_toTokenId].push(_tokenId);
    tokenIdToChildTokenIdsIndex[_tokenId] = index;

    // this also prevents circular token ownership by causing out of gas error
    require(ERC721(_toContract).ownerOf(_toTokenId) != address(0), "_toTokenId does not exist");

    emit Transfer(_from, _toContract, _tokenId);
    emit TransferToParent(_toContract, _toTokenId, _tokenId);
  }


  function transferAsChild(address _fromContract, uint256 _fromTokenId, address _toContract, uint256 _toTokenId, uint256 _tokenId) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
    require(tokenOwner == _fromContract);
    require(_toContract != address(0));
    uint256 parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
    require(parentTokenId > 0, "No parent token to transfer from.");
    require(parentTokenId-1 == _fromTokenId);
    address rootOwner = ownerOf(_tokenId);
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);

    // clear approval
    if(rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] != address(0)) {
      delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    // remove and transfer token
    if(_fromContract != _toContract) {
      assert(tokenOwnerToTokenCount[_fromContract] > 0);
      tokenOwnerToTokenCount[_fromContract]--;
      tokenOwnerToTokenCount[_toContract]++;
    }

    TokenOwner memory parentToken = TokenOwner(_toContract, _toTokenId);
    tokenIdToTokenOwner[_tokenId] = parentToken;

    removeChild(_fromContract, _fromTokenId,_tokenId);

    //add to parentToChildTokenIds
    uint256 index = parentToChildTokenIds[_toContract][_toTokenId].length;
    parentToChildTokenIds[_toContract][_toTokenId].push(_tokenId);
    tokenIdToChildTokenIdsIndex[_tokenId] = index;

    // this also prevents circular token ownership by causing out of gas error
    require(ERC721(_toContract).ownerOf(_toTokenId) != address(0), "_toTokenId does not exist");

    emit Transfer(_fromContract, _toContract, _tokenId);
    emit TransferFromParent(_fromContract, _fromTokenId, _tokenId);
    emit TransferToParent(_toContract, _toTokenId, _tokenId);

  }

  function removeChild(address _fromContract, uint256 _fromTokenId, uint256 _tokenId) internal {
    uint256 childTokenIndex = tokenIdToChildTokenIdsIndex[_tokenId];
    uint256 lastChildTokenIndex = parentToChildTokenIds[_fromContract][_fromTokenId].length - 1;
    uint256 lastChildTokenId = parentToChildTokenIds[_fromContract][_fromTokenId][lastChildTokenIndex];

    if(_tokenId != lastChildTokenId) {
      parentToChildTokenIds[_fromContract][_fromTokenId][childTokenIndex] = lastChildTokenId;
      tokenIdToChildTokenIdsIndex[lastChildTokenId] = childTokenIndex;
    }
    parentToChildTokenIds[_fromContract][_fromTokenId].length--;
  }

}