// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * GBCEntitlement
 * - ERC20-like token (minimal implementation)
 * - Admin-only: mint/approve addresses, adminTransfer, set caps
 * - Users: claim() once, capped by entitlementCap
 *
 * Notes:
 * - This is a simplified ERC20. If you prefer OpenZeppelin ERC20, I’ll provide that version too.
 */
contract GBCEntitlement {
    // ====== ERC20 basics ======
    string public name = "Global Birthright Currency";
    string public symbol = "GBC";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ====== Admin + Entitlement ======
    address public admin;
    uint256 public entitlementCap; // e.g., 0.0125 * 1e18
    mapping(address => bool) public approved;     // who is allowed to claim
    mapping(address => bool) public hasClaimed;   // claim only once

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event Approved(address indexed user, bool allowed);
    event Claimed(address indexed user, uint256 amount);
    event EntitlementCapChanged(uint256 oldCap, uint256 newCap);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(
        address _admin,
        uint256 _initialSupply,
        uint256 _entitlementCap
    ) {
        require(_admin != address(0), "admin=0");
        admin = _admin;
        entitlementCap = _entitlementCap;

        // mint initial supply to admin
        _mint(_admin, _initialSupply);
    }

    // ====== ERC20 functions ======
    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "Allowance too low");
        allowance[from][msg.sender] = allowed - value;
        _transfer(from, to, value);
        return true;
    }

    // ====== Admin controls ======
    function setAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "newAdmin=0");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function setEntitlementCap(uint256 newCap) external onlyAdmin {
        require(newCap > 0, "cap=0");
        emit EntitlementCapChanged(entitlementCap, newCap);
        entitlementCap = newCap;
    }

    function setApproved(address user, bool allowed) external onlyAdmin {
        approved[user] = allowed;
        emit Approved(user, allowed);
    }

    function batchSetApproved(address[] calldata users, bool allowed) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            approved[users[i]] = allowed;
            emit Approved(users[i], allowed);
        }
    }

    // Admin can distribute tokens (admin-locked send)
    function adminTransfer(address to, uint256 value) external onlyAdmin returns (bool) {
        _transfer(admin, to, value);
        return true;
    }

    // ====== User claim flow ======
    function claim() external returns (bool) {
        require(approved[msg.sender], "Not approved");
        require(!hasClaimed[msg.sender], "Already claimed");

        hasClaimed[msg.sender] = true;
        _mint(msg.sender, entitlementCap);

        emit Claimed(msg.sender, entitlementCap);
        return true;
    }

    // ====== internal helpers ======
    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "to=0");
        require(balanceOf[from] >= value, "Balance too low");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}
