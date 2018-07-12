pragma solidity ^0.4.24;

import "./interfaces/ERC998ERC721TopDownEnumerableI.sol";
import "./ERC998ERC721TopDown.sol";

contract ERC998ERC721TopDownEnumerable is ERC998ERC721TopDownEnumerableI, ERC998ERC721TopDown {
  function childExists(address _childContract, uint256 _childTokenId) external view returns (bool) {
    uint256 tokenId = childTokenOwner[_childContract][_childTokenId];
    return childTokenIndex[tokenId][_childContract][_childTokenId] != 0;
  }

  function totalChildContracts(uint256 _tokenId) external view returns(uint256) {
    return childContracts[_tokenId].length;
  }

  function childContractByIndex(uint256 _tokenId, uint256 _index) external view returns (address childContract) {
    require(_index < childContracts[_tokenId].length, "Contract address does not exist for this token and index.");
    return childContracts[_tokenId][_index];
  }

  function totalChildTokens(uint256 _tokenId, address _childContract) external view returns(uint256) {
    return childTokens[_tokenId][_childContract].length;
  }

  function childTokenByIndex(uint256 _tokenId, address _childContract, uint256 _index) external view returns (uint256 childTokenId) {
    require(_index < childTokens[_tokenId][_childContract].length, "Token does not own a child token at contract address and index.");
    return childTokens[_tokenId][_childContract][_index];
  }
}

