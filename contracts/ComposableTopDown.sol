/**********************************
/* Author: Nick Mudge, <nick@perfectabstractions.com>, https://medium.com/@mudgen.
/**********************************/

//jshint ignore: start

pragma solidity ^0.4.24;

import "./ERC998ERC721TopDownEnumerable.sol";
import "./ERC998ERC20TopDownEnumerable.sol";

contract ComposableTopDown is ERC998ERC721TopDownEnumerable, ERC998ERC20TopDownEnumerable {
  // wrapper on minting new 721
  function mint(address _to) public returns(uint256) {
    tokenCount++;
    uint256 tokenCount_ = tokenCount;
    tokenIdToTokenOwner[tokenCount_] = _to;
    tokenOwnerToTokenCount[_to]++;
    return tokenCount_;
  }  
}