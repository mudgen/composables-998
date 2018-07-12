pragma solidity ^0.4.24;

import "./interfaces/ERC998ERC721BottomUpEnumerableI.sol";
import "./ERC998ERC721BottomUp.sol";

contract ERC998ERC721BottomUpEnumerable is ERC998ERC721BottomUpEnumerableI, ERC998ERC721BottomUp {
  function totalChildTokens(address _parentContract, uint256 _parentTokenId) public view returns(uint256) {
    return parentToChildTokenIds[_parentContract][_parentTokenId].length;
  }

  function childTokenByIndex(address _parentContract, uint256 _parentTokenId, uint256 _index) public view returns(uint256) {
    require(parentToChildTokenIds[_parentContract][_parentTokenId].length > _index);
    return parentToChildTokenIds[_parentContract][_parentTokenId][_index];
  }
}

