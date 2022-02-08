pragma solidity ^0.5.6;

import "./ownership/Ownable.sol";
import "./math/SafeMath.sol";
import "./interface/IGusuelV2.sol";
import "./token/KIP37/KIP37Burnable.sol";
import "./token/KIP17/IKIP17.sol";

contract GuseulKongChick is Ownable, IGuseulV2 {
    using SafeMath for uint256;

    KIP37Burnable public coupon;
    IKIP17 public kongz;
    IKIP17 public chickiz;

    // token Metadata
    string public constant tokenName = "Gusuel KongChick";
    string public constant tokenSymbol = "GSL";
    uint8 public constant tokenDecimals = 4;
    uint256 public constant freeTerm = 43200;
    uint256 public constant freeDrop = 100000000;

    function name() external pure returns (string memory) {
        return tokenName;
    }

    function symbol() external pure returns (string memory) {
        return tokenSymbol;
    }

    function decimals() external pure returns (uint8) {
        return tokenDecimals;
    }

    // totalSupply & balances
    uint256 public tokenTotalSupply = 0;
    uint256 public round = 1;

    struct UserInfo {
        uint8 oddEven;
        uint256 initialBalance;
        uint256 canEarn;
        uint256 lastRound;
        uint256 freeBlock;
    }

    mapping(address => UserInfo) public _userInfo;

    //round => user => uint256, bool
    mapping(uint256 => mapping(address => bool)) private _betBool;
    mapping(uint256 => mapping(address => uint256)) private _betQuan;

    // odd = 1, even = 2
    mapping(uint256 => uint8) public _roundResult;

    function totalSupply() external view returns (uint256) {
        return tokenTotalSupply;
    }

    function balanceOf(address user) external view returns (uint256 balance) {
        return balances(user);
    }

    function balances(address user) public view returns (uint256 balance) {
        UserInfo memory _uInfo = _userInfo[user];

        if (_roundResult[_uInfo.lastRound] == _uInfo.oddEven) {
            return _uInfo.canEarn.add(_uInfo.initialBalance);
        }
        return _uInfo.initialBalance;
    }

    constructor(
        KIP37Burnable _coupon,
        IKIP17 _kongz,
        IKIP17 _chickiz
    ) public {
        canTransfer[msg.sender] = true;
        coupon = _coupon;
        kongz = _kongz;
        chickiz = _chickiz;
    }

    // only able to transfer when canTransfer is true

    mapping(address => bool) public canTransfer;

    function addCanTransfer(address adr) external onlyOwner {
        canTransfer[adr] = true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "KIP7: transfer from the zero address");
        require(to != address(0), "KIP7: transfer to the zero address");

        emit Transfer(from, to, amount);
    }

    function transfer(address to, uint256 amount)
        external
        returns (bool success)
    {
        require(canTransfer[msg.sender] == true, "not Allowed");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success) {
        require(canTransfer[msg.sender] == true, "not Allowed");
        _transfer(from, to, amount);
        return true;
    }

    //airdrop

    function airdrop(address[] memory adr, uint256 quant) public onlyOwner {
        uint256 len = adr.length;
        for (uint256 i = 0; i < len; i++) {
            UserInfo storage _thisInfo = _userInfo[adr[i]];
            _thisInfo.initialBalance = _thisInfo.initialBalance.add(quant);
            emit Transfer(msg.sender, adr[i], quant);
        }
    }

    //game

    function freeGsl() public {
        UserInfo memory _uInfo = _userInfo[msg.sender];
        uint256 _uBalance = _uInfo.initialBalance;
        uint256 _possibleBlock = _uInfo.freeBlock.add(freeTerm);
        uint256 _kongzBalance = kongz.balanceOf(msg.sender);
        uint256 _chickizBalance = chickiz.balanceOf(msg.sender);
        require(_kongzBalance.add(_chickizBalance) > 0);
        require(_possibleBlock <= block.number);

        UserInfo storage _thisInfo = _userInfo[msg.sender];

        _thisInfo.freeBlock = block.number;
        _thisInfo.initialBalance = _uBalance.add(freeDrop);
        emit Transfer(msg.sender, msg.sender, freeDrop);
    }

    function raffle(uint8 __result) public onlyOwner {
        _roundResult[round] = __result;
        round = round.add(1);
    }

    function bet(uint8 _oddEven, uint256 _howMuch) public {
        require(_betBool[round][msg.sender] != true);
        UserInfo storage _thisInfo = _userInfo[msg.sender];

        uint256 nowQuant = balances(msg.sender);

        _betBool[round][msg.sender] = true;
        _betQuan[round][msg.sender] = _howMuch;

        _thisInfo.oddEven = _oddEven;
        _thisInfo.initialBalance = nowQuant.sub(_howMuch);
        _thisInfo.canEarn = _howMuch.mul(2);
        _thisInfo.lastRound = round;
        emit Transfer(msg.sender, msg.sender, 0);
    }

    function betWithCoupon(uint8 _oddEven, uint256 _howMuch) public {
        require(_betBool[round][msg.sender] != true);
        coupon.burn(msg.sender, 0, 1);
        UserInfo storage _thisInfo = _userInfo[msg.sender];

        uint256 nowQuant = balances(msg.sender);

        _betBool[round][msg.sender] = true;
        _betQuan[round][msg.sender] = _howMuch;

        _thisInfo.oddEven = _oddEven;
        _thisInfo.initialBalance = nowQuant.sub(_howMuch);
        _thisInfo.canEarn = _howMuch.mul(3);
        _thisInfo.lastRound = round;
        emit Transfer(msg.sender, msg.sender, 0);
    }

    function refresh() public {
        emit Transfer(msg.sender, msg.sender, 0);
    }

    // view

    function betOrNot(address adr) public view returns (bool) {
        return _betBool[round][adr];
    }

    function thisRoundBet(address adr) public view returns (uint256) {
        return _betQuan[round][adr];
    }

    function lastRoundEarn(address adr) public view returns (uint256) {
        UserInfo memory _uInfo = _userInfo[adr];

        if (
            _uInfo.lastRound == round.sub(1) &&
            _roundResult[_uInfo.lastRound] == _uInfo.oddEven
        ) {
            return _uInfo.canEarn;
        }
        return 0;
    }

    function kongchickPoint(address adr) public view returns (uint256) {
        return kongz.balanceOf(adr).mul(7).add(chickiz.balanceOf(adr));
    }

    //burn

    function burnAll(address[] memory adr) public onlyOwner {
        uint256 len = adr.length;
        for (uint256 i = 0; i < len; i++) {
            UserInfo storage _thisInfo = _userInfo[adr[i]];

            _thisInfo.initialBalance = 0;
            emit Transfer(adr[i], adr[i], 0);
        }
        tokenTotalSupply = 0;
        round = round.add(1);
    }
}
