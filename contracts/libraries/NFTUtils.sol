// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title NFTUtils
 * @dev Utility library for NFT-related operations
 */
library NFTUtils {
    /**
     * @dev Check if an address is a contract
     * @param addr The address to check
     * @return bool True if the address is a contract
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Validate token ID range
     * @param tokenId The token ID to validate
     * @param maxSupply Maximum supply allowed
     * @return bool True if token ID is valid
     */
    function isValidTokenId(uint256 tokenId, uint256 maxSupply) internal pure returns (bool) {
        return tokenId > 0 && tokenId <= maxSupply;
    }

    /**
     * @dev Calculate royalty amount
     * @param salePrice The sale price
     * @param royaltyBasisPoints Royalty in basis points (e.g., 250 = 2.5%)
     * @return uint256 Royalty amount
     */
    function calculateRoyalty(uint256 salePrice, uint256 royaltyBasisPoints) internal pure returns (uint256) {
        return (salePrice * royaltyBasisPoints) / 10000;
    }

    /**
     * @dev Generate a pseudo-random number (not cryptographically secure)
     * @param seed Additional seed for randomness
     * @param max Maximum value (exclusive)
     * @return uint256 Random number
     */
    function random(uint256 seed, uint256 max) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, seed))) % max;
    }
}
