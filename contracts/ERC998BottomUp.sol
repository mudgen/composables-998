pragma solidity ^0.4.24;

import "./interfaces/ERC998.sol";
import "./interfaces/ERC721Receiver.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";


contract ERC998BottomUp is ERC998 {
  using SafeMath for uint256;

  struct TokenOwner {
    address tokenOwner;
    uint256 parentTokenId;
  }

  // tokenOwnerOf.selector;
  uint256 constant TOKEN_OWNER_OF = 0x89885a59;

  // tokenId => token owner
  mapping (uint256 => TokenOwner) internal tokenIdToTokenOwner;

  // root token owner address => (tokenId => approved address)
  mapping (address => mapping (uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;

  // token owner address => token count
  mapping (address => uint256) internal tokenOwnerToTokenCount;

  // token owner => (operator address => bool)
  mapping (address => mapping (address => bool)) internal tokenOwnerToOperators;

  // parent address => (parent tokenId => array of child tokenIds)
  mapping (address => mapping(uint256 => uint256[])) internal parentToChildTokenIds;

  // tokenId => position in childTokens array
  mapping (uint256 => uint256) internal tokenIdToChildTokenIdsIndex;

  // wrapper on minting new 721
  /*
  function mint721(address _to) public returns(uint256) {
    _mint(_to, allTokens.length + 1);
    return allTokens.length;
  }
  */
  //from zepellin ERC721Receiver.sol
  //old version
  bytes4 constant ERC721_RECEIVED = 0x150b7a02;

  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

  function tokenOwnerOf(uint256 _tokenId) public view returns (address tokenOwner, uint256 parentTokenId, uint256 isParent) {
    tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
    require(tokenOwner != address(0));
    parentTokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
    if(parentTokenId > 0) {
      isParent = TOKEN_OWNER_OF << 8 | 1;
      parentTokenId--;
    }
    else {
      isParent = TOKEN_OWNER_OF << 8;
    }
    return (tokenOwner, parentTokenId, isParent);
  }

  // returns the root owner at the top of the tree of composables
  function ownerOf(uint256 _tokenId) public view returns (address rootOwner) {
    rootOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
    require(rootOwner != address(0));
    _tokenId = tokenIdToTokenOwner[_tokenId].parentTokenId;
    bool callSuccess;
    uint256 isParent = _tokenId;
    _tokenId--;
    bytes memory calldata;
    while(uint8(isParent) > 0) {
      if(rootOwner == address(this)) {
        (rootOwner,_tokenId,isParent) = tokenOwnerOf(_tokenId);
      }
      else {
        //0x89885a59 == "tokenOwnerOf(uint256)"
        calldata = abi.encodeWithSelector(0x89885a59, _tokenId);
        assembly {
          callSuccess := staticcall(gas, rootOwner, add(calldata, 0x20), mload(calldata), calldata, 0x60)
          if callSuccess {
            rootOwner := mload(calldata)
            _tokenId := mload(add(calldata,0x20))
            isParent := mload(add(calldata,0x40))
          }
        }

        if(callSuccess == false || isParent >> 8 != TOKEN_OWNER_OF) {
          //0x6352211e == "ownerOf(uint256)"
          calldata = abi.encodeWithSelector(0x6352211e, _tokenId);
          assembly {
            callSuccess := staticcall(gas, rootOwner, add(calldata, 0x20), mload(calldata), calldata, 0x20)
            if callSuccess {
              rootOwner := mload(calldata)
            }
          }
          require(callSuccess, "rootOwnerOf failed");
          isParent = 0;
        }
      }
    }
    return rootOwner;
  }

  function balanceOf(address _tokenOwner)  external view returns (uint256) {
    require(_tokenOwner != address(0));
    return tokenOwnerToTokenCount[_tokenOwner];
  }


  function approve(address _approved, uint256 _tokenId) external {
    address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
    address rootOwner = ownerOf(_tokenId);
    require(tokenOwner != address(0));
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender]
      || tokenOwner == msg.sender  || tokenOwnerToOperators[tokenOwner][msg.sender]);

    rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] = _approved;
    emit Approval(rootOwner, _approved, _tokenId);
  }

  function getApproved(uint256 _tokenId) public view returns (address)  {
    address rootOwner = ownerOf(_tokenId);
    return rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
  }

  function setApprovalForAll(address _operator, bool _approved) external {
    require(_operator != address(0));
    tokenOwnerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function isApprovedForAll(address _owner, address _operator ) external  view returns (bool)  {
    require(_owner != address(0));
    require(_operator != address(0));
    return tokenOwnerToOperators[_owner][_operator];
  }

  function _transferFrom(address _from, address _to, uint256 _tokenId) private {
    address tokenOwner = tokenIdToTokenOwner[_tokenId].tokenOwner;
    require(tokenOwner == _from);
    require(tokenIdToTokenOwner[_tokenId].parentTokenId == 0, "Cannot transfer from address when owned by a token.");
    require(_to != address(0));
    address rootOwner = ownerOf(_tokenId);
    require(rootOwner == msg.sender || tokenOwnerToOperators[rootOwner][msg.sender] ||
      rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] == msg.sender ||
      tokenOwner == msg.sender || tokenOwnerToOperators[tokenOwner][msg.sender]);

    // clear approval
    if(rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId] != address(0)) {
      delete rootOwnerAndTokenIdToApprovedAddress[rootOwner][_tokenId];
    }

    // remove and transfer token
    if(_from != _to) {
      assert(tokenOwnerToTokenCount[_from] > 0);
      tokenOwnerToTokenCount[_from] = tokenOwnerToTokenCount[_from] - 1;
      tokenIdToTokenOwner[_tokenId].tokenOwner = _to;
      tokenOwnerToTokenCount[_to] = tokenOwnerToTokenCount[_to] + 1;
    }
    emit Transfer(_from, _to, _tokenId);

    if(isContract(_from)) {
      //0x0da719ec == "onERC998Removed(address,address,uint256,bytes)"
      bytes memory calldata = abi.encodeWithSelector(0x0da719ec, msg.sender, _to, _tokenId,"");
      assembly {
        let success := call(gas, _from, 0, add(calldata, 0x20), mload(calldata), calldata, 0)
      }
    }
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external {
    _transferFrom(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
    _transferFrom(_from, _to, _tokenId);
    if(isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "");
      require(retval == ERC721_RECEIVED);
    }
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
    _transferFrom(_from, _to, _tokenId);
    if(isContract(_to)) {
      bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == ERC721_RECEIVED);
    }
  }
}