pragma solidity ^0.5.6;

interface IGuseulV2 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 amount
    // );

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function transfer(address to, uint256 amount)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    function addCanTransfer(address adr) external;

    // function approve(address spender, uint256 amount)
    //     external
    //     returns (bool success);

    // function allowance(address owner, address spender)
    //     external
    //     view
    //     returns (uint256 remaining);
}
