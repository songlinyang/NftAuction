library MyConcat {
    /**
     * @dev Concatenate two strings
     * @param a First string
     * @param b Second string
     * @return string Concatenated result
     */
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
        /**
     * @dev Concatenate two strings
     * @param a First string
     * @param b Second uint256
     * @return string Concatenated result
     */
     function concat(string memory a, uint256 b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, _toString(b)));
     }

     /**
      * @dev Converts a `uint256` to its ASCII `string` decimal representation.
      */
     function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
     }
}