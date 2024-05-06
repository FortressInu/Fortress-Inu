// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IAccessControl {
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AccessControlBadConfirmation();
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }
    mapping(bytes32 role => RoleData) private _roles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].hasRole[account];
    }
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
    function _grantRole(bytes32 role, address account) internal virtual returns (bool) {
        if (!hasRole(role, account)) {
            _roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, _msgSender());
            return true;
        } else {
            return false;
        }
    }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function percent(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= 100, "SafeMath: percentage greater than 100");
        uint256 c = mul(a, b);
        return div(c, 100);
    }
}
interface IProposalManagement {
    function isProposalApproved(uint256 proposalId) external view returns (address eventAddress, uint256 amount, bool approve);
}
interface IBEP20Core {
    function balanceOf(address _someone) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function burn(uint256 _amount) external returns (bool);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, address indexed _to, uint256 _value);
}
interface IBEP20Metadata is IBEP20Core {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract IBEP20 is Context, IBEP20Core, IBEP20Metadata {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint256 public totalSupply = 100 * (10**9 * 10**18);
    uint256 public currentSupply = totalSupply;
    uint256 public totalBurnedAmount;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual override returns (string memory) { return _name;}
    function symbol() public view virtual override returns (string memory) { return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function balanceOf(address _account) public view virtual override returns (uint256) {return _balances[_account];}
    function allowance(address _account, address _spender) public view virtual override returns (uint256) {
        return _allowances[_account][_spender];
    }
    function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
        require(_recipient != address(0), "Invalid Wallet Address");
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }
    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }
    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) public virtual override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), _allowances[_sender][_msgSender()].sub(_amount, "Insufficient Balance"));
        return true;
    }
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].add(_addedValue));
        return true;
    }
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), _spender, _allowances[_msgSender()][_spender].sub(_subtractedValue, "Invalid Amount"));
        return true;
    }
    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_sender != address(0), "Invalid Wallet Address");
        _balances[_sender] = _balances[_sender].sub(_amount, "Insufficient Fund");
        _balances[_recipient] = _balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }
    function _mintTokens(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "Invalid Wallet Address");
        _balances[_account] = _balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }
    function _approve(
        address _account,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_account != address(0), "Invalid Wallet Address");
        require(_spender != address(0), "Invalid Wallet Address");
        _allowances[_account][_spender] = _amount;
        emit Approval(_account, _spender, _amount);
    }
    function burn(uint256 _amount) public returns (bool) {
        require(_amount > 0, "Invalid burn amount");
        require(_balances[_msgSender()] >= _amount, "Insufficient balance to burn");
        _burn(_msgSender(), _amount);
        return true;
    }
    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "Invalid Wallet Address");
        _transfer(_account, address(0), _amount);
        totalSupply = totalSupply.sub(_amount);
        totalBurnedAmount += _amount;
        emit Transfer(_account, address(0), _amount);
    }
}
interface IUniswapV2Router {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
contract FortressInu is IBEP20, AccessControl{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bool private stakingEvent = true;
    uint256 private developmentShare;
    uint256 private burnShare;
    address constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private developmentTeam = 0x75DD50C7311b75f552dFC2cAb99039cda3e730Ed;
    address private stakingAddress;
    event LiquidityAdded(address indexed dexAddress, uint amountToken, uint amountBNB);
    event TokensBurned(address indexed burner, uint256 amount);
    event TeamPayment(address teamMember, uint256 amount);
    event TokensPurchased(address buyer, uint256 tokensBought);
    event TokensSentToStakingEvent(address indexed stakingAddress, uint256 amount);
    mapping (address => bool) private _isExcludedFromFees;
    mapping(address => bool) public pairCreated; 
    address public tokenAddress; 
    address public WETH; 
    IUniswapV2Router public dexRouter;
    address private liquidityTokenAddress;
    mapping (address => mapping (address => uint256)) private _allowances;
    constructor() IBEP20("Fortress Inu", "FINU"){
        _mintTokens(address(this), 100 * (10**9 * 10**18)); 
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(ADMIN_ROLE, _msgSender());
        _isExcludedFromFees[_msgSender()] = true;
        _isExcludedFromFees[developmentTeam] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[deadWallet] = true;
        _isExcludedFromFees[address(0)] = true;
        tokenAddress = address(this);
        developmentShare = 3;
        burnShare = 1;
        dexRouter = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        WETH = dexRouter.WETH();
        ensureLiquidityPair();
        presaleActive = true;
    } 
    function sendTokensToStakingEvent(address _stakingAddress) external onlyRole(ADMIN_ROLE) {
        require(_stakingAddress != address(0), "Invalid address");
        require(stakingEvent, "Tokens have already been allocated to the staking event; further transfers are not permitted.");
        stakingEvent = false;
        stakingAddress = _stakingAddress;
        uint256 tokensToSend = 15 * (10**9 * 10**18); 
        require(balanceOf(tokenAddress) >= tokensToSend, "Insufficient tokens in contract");
        bool sent = this.transfer(_stakingAddress, tokensToSend);
        currentSupply = currentSupply - tokensToSend;
        require(sent, "Token transfer failed");
        emit TokensSentToStakingEvent(_stakingAddress, tokensToSend);
    }
    function addExcludedFeesAddress(address _feeExcludedAddress) external onlyRole(ADMIN_ROLE) {
        _isExcludedFromFees[_feeExcludedAddress] = true;
    }
    function removeExcludedFeesAddress(address _feeExcludedAddress) external onlyRole(ADMIN_ROLE) {
        _isExcludedFromFees[_feeExcludedAddress] = false;
    }
    function getThisBalance() external view returns (uint256) {
        return balanceOf(tokenAddress);
    }
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        require(_from != address(0), "Invalid Address Detected");
        if (_amount == 0) {
            super._transfer(_from, _to, 0);
            return;
        }
        uint256 feesToDeduct = 0;
        if (!_isExcludedFromFees[_from] && !_isExcludedFromFees[_to]) {
            uint256 teamFee = calculatePercentage(_amount, developmentShare);
            uint256 burnFee = calculatePercentage(_amount, burnShare);
            feesToDeduct = teamFee + burnFee;
            if (teamFee > 0) {
                super._transfer(_from, developmentTeam, teamFee);
            }
            if (burnFee > 0) {
                _burn(_from, burnFee);
            }
        }
        uint256 netAmount = _amount - feesToDeduct;
        super._transfer(_from, _to, netAmount);
    }
    function getContractBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function updateTeamWalletAddress(address _newWallet) external onlyRole(ADMIN_ROLE) {
        developmentTeam = _newWallet;
    }
    function ensureLiquidityPair() private {
        if (!pairCreated[address(dexRouter)]) {
            address factory = dexRouter.factory();
            IUniswapV2Factory uniswapFactory = IUniswapV2Factory(factory);
            uniswapFactory.createPair(tokenAddress, WETH);
            pairCreated[address(dexRouter)] = true;
        }
    }
    function addLiquidity(uint256 _tokenAmount, uint256 _bnbAmount) external onlyRole(ADMIN_ROLE){
        require(balanceOf(tokenAddress) >= _tokenAmount, "Not enough tokens in the contract");
        require(tokenAddress.balance >= _bnbAmount, "Not enough BNB in the contract");
        _approve(tokenAddress, address(dexRouter), _tokenAmount);
        currentSupply = currentSupply - _tokenAmount;
        (,, uint liquidity) = dexRouter.addLiquidityETH{ value: _bnbAmount }(
            tokenAddress,
            _tokenAmount,
            0, 
            0, 
            _msgSender(), 
            block.timestamp + 300 
        );
        require(liquidity > 0, "Failed to add liquidity");
        address factory = dexRouter.factory();
        liquidityTokenAddress = IUniswapV2Factory(factory).getPair(tokenAddress, WETH);
    }
    function getLiquidityTokenAddress() external view returns (address) {
        require(liquidityTokenAddress != address(0), "LP Token address not set");
        return liquidityTokenAddress;
    }
    function getBNBLiquidityBalance() external view returns (uint256) {
        if (liquidityTokenAddress == address(0)) {
            return 0; 
        }
        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(liquidityTokenAddress).getReserves();
        address token0 = IUniswapV2Pair(liquidityTokenAddress).token0();
        if (token0 == tokenAddress) {
            return reserve1;
        } else {
            return reserve0;
        }
    }
    function getTokenLiquidityBalance() external view returns (uint256) {
        if (liquidityTokenAddress == address(0)) {
            return 0; 
        }
        IUniswapV2Pair pair = IUniswapV2Pair(liquidityTokenAddress);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        if (token0 == tokenAddress) {
            return reserve0; 
        } else {
            return reserve1; 
        }
    }
    using SafeMath for uint256;
    bool public presaleActive;
    uint256 public presaleTotalSupply = 10 * (10**9 * 10**18); 
    uint256 public presaleCurrentSupply = presaleTotalSupply;
    uint256 public presaleTokenSold;
    uint256 public bnbPrice;
    uint256 public presaleStage = 1;
    uint256[4] private tokenPrice = [1000000000000, 1100000000000, 1200000000000, 1300000000000];
    event PresaleContributionReceived(address contributor, uint256 bnbAmount);
    event PresaleSupplyUpdated(uint256 newSupply);
    receive() external payable {
        if(presaleActive){
            require(msg.value > 0, "BNB sent must be greater than 0");
            emit PresaleContributionReceived(_msgSender(), msg.value);
            uint256 _fortress = calculateIntoFortressInuTokenAmount(msg.value);
            require(_fortress <= presaleCurrentSupply, "Not enough tokens left");
            uint256 _tokensToBurn = calculatePercentage(_fortress, burnShare);
            uint256 _teamShare = calculatePercentage(_fortress, developmentShare);
            uint256 _tokensToBuy = _fortress - _tokensToBurn - _teamShare;
            _transfer(tokenAddress, _msgSender(), _tokensToBuy);
            emit TokensPurchased(_msgSender(), _tokensToBuy);
            setPresaleCurrentSupply(_tokensToBurn + _tokensToBuy);
            currentSupply -= (_tokensToBurn + _tokensToBuy);
            presaleTokenSold += _tokensToBuy;
            emit PresaleSupplyUpdated(presaleCurrentSupply);
            _burn(tokenAddress, _tokensToBurn);
            emit TokensBurned(_msgSender(), _tokensToBurn);
            uint256 _teamShareInBNB = calculatePercentage(msg.value, developmentShare);
            payTheTeam(_teamShareInBNB);
            updatePresaleStage();
        }
    }    
    function payTheTeam(uint _amount) private {
        payable(developmentTeam).transfer(_amount);
        emit TeamPayment(developmentTeam, _amount);
    }    
    function endPresale() external onlyRole(ADMIN_ROLE) {
        require(presaleActive, "Presale is already inactive");
        presaleActive = false;
    } 
    function calculatePercentage(uint256 _amount, uint256 _percentage) internal pure returns (uint256) {
        return _amount.percent(_percentage);
    }
    function setPresaleCurrentSupply(uint256 _amount) private {
        presaleCurrentSupply = presaleCurrentSupply.sub(_amount);
    }
    function getTokenPrice() public view returns (uint256) {
        return tokenPrice[presaleStage - 1];
    }
    function getBNBPriceUSD() public view returns (uint256) {
        return bnbPrice / (10**18);
    }
    function updateBNBPrice(uint256 _bnbPrice) external onlyRole(ADMIN_ROLE) {
        bnbPrice = (_bnbPrice * (1 * 10**18));
    }
    function updatePresaleStage() internal {
        uint256 soldPercentage = ((presaleTokenSold + totalBurnedAmount) * 100) / presaleTotalSupply;
        if (soldPercentage >= 75) { 
            presaleStage = 4;
        } else if (soldPercentage >= 50) {
            presaleStage = 3;
        } else if (soldPercentage >= 25) {
            presaleStage = 2;
        }
    }
    function calculateIntoFortressInuTokenAmount(uint256 _amountBNB) internal view returns (uint256) {
        require(bnbPrice > 0, "Invalid BNB price");
        uint256 _amountUSD = _amountBNB * bnbPrice; 
        return _amountUSD / tokenPrice[presaleStage - 1] ; 
    }
    IProposalManagement public proposalManagement;
    bool setProposalAddress = true;
    function setProposalManagementAddress(address _proposalManagementAddress) external onlyRole(ADMIN_ROLE) {
        require(setProposalAddress, "Address already set");
        proposalManagement = IProposalManagement(_proposalManagementAddress);
        setProposalAddress = false;
    }
    function isProposalApproved(uint256 proposalId) external onlyRole(ADMIN_ROLE) {
        (address eventAddress, uint256 amount, bool approved) = proposalManagement.isProposalApproved(proposalId);
        require(approved, "Proposal not approved");
        require(balanceOf(tokenAddress) >= amount, "Insufficient funds for event");
        bool sent = this.transfer(eventAddress, amount);
        require(sent, "Token transfer failed");
    }
}
contract StakingContract {
    IBEP20 public stakingToken;
    uint256 public stakingTotalSupply = 15 * 10**9 * 10**18; 
    uint256 private stakingCurrentSupply;
    uint256 public totalStaked;
    uint256 public rewardPaid;
    struct Stake {
        uint256 amount;
        uint256 stakingTimestamp;
        uint256 stakingTerm;
        uint256 annualRate;
    }
    mapping(address => Stake[]) public stakerStakes;
    address[] private stakers;
    event Staked(address indexed staker, uint256 amount, uint256 term, uint256 rate);
    event Unstaked(address indexed staker, uint256 amount);
    constructor(address _stakingToken) {
        stakingToken = IBEP20(_stakingToken);
    }
    function stake(uint256 amount, uint256 stakingTerm) external {
        require(amount > 0, "Amount must be greater than 0");
        require(stakingTerm >= 1 days, "Staking term must be at least 1 minute"); 
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        uint256 rate = getAnnualRate(stakingTerm);
        uint256 reward = calculateRewards(amount, rate, stakingTerm);
        require(reward <= getStakingCurrentSupply(), "Not enough tokens left for staking and rewards");
        totalStaked += amount;
        if (stakerStakes[msg.sender].length == 0) {
            stakers.push(msg.sender);
        }
        stakerStakes[msg.sender].push(Stake({
            amount: amount,
            stakingTimestamp: block.timestamp,
            stakingTerm: stakingTerm,
            annualRate: rate
        }));
        emit Staked(msg.sender, amount, stakingTerm, rate);
    }
    function unstake(uint index) external {
        require(index < stakerStakes[msg.sender].length, "Invalid index");
        Stake storage selectedStake = stakerStakes[msg.sender][index];
        require(block.timestamp >= selectedStake.stakingTimestamp + selectedStake.stakingTerm, "Staking term has not ended yet");
        uint256 duration = block.timestamp - selectedStake.stakingTimestamp;
        uint256 reward = calculateRewards(selectedStake.amount, selectedStake.annualRate, duration);
        uint256 totalAmount;
        if (reward > getStakingCurrentSupply()) {
            totalAmount = selectedStake.amount + getStakingCurrentSupply();  
            rewardPaid += getStakingCurrentSupply();
        } else {
            totalAmount = selectedStake.amount + reward;
            rewardPaid += reward;
        }
        totalStaked -= selectedStake.amount;
        require(stakingToken.transfer(msg.sender, totalAmount), "Transfer failed");
        stakerStakes[msg.sender][index] = stakerStakes[msg.sender][stakerStakes[msg.sender].length - 1];
        stakerStakes[msg.sender].pop();
        if (stakerStakes[msg.sender].length == 0) {
            removeStaker(msg.sender);
        }
        emit Unstaked(msg.sender, totalAmount);
    }
    function removeStaker(address staker) private {
        for (uint i = 0; i < stakers.length; i++) {
            if (stakers[i] == staker) {
                stakers[i] = stakers[stakers.length - 1];
                stakers.pop();
                break;
            }
        }
    }
    function getStakeInfo(address staker) public view returns (uint256[] memory amounts, uint256[] memory startTimes, uint256[] memory terms, uint256[] memory rates, uint256[] memory rewards) {
        uint256 stakeCount = stakerStakes[staker].length;
        amounts = new uint256[](stakeCount);
        startTimes = new uint256[](stakeCount);
        terms = new uint256[](stakeCount);
        rates = new uint256[](stakeCount);
        rewards = new uint256[](stakeCount);
        for (uint256 i = 0; i < stakeCount; i++) {
            Stake storage selectStake = stakerStakes[staker][i];
            amounts[i] = selectStake.amount;
            startTimes[i] = selectStake.stakingTimestamp;
            terms[i] = selectStake.stakingTerm;
            rates[i] = selectStake.annualRate;
            uint256 duration = block.timestamp - selectStake.stakingTimestamp;
            rewards[i] = calculateRewards(selectStake.amount, selectStake.annualRate, duration);
        }
        return (amounts, startTimes, terms, rates, rewards);
    }
    function getTotalStakers() public view returns (uint256) {
        return stakers.length;
    }
    function calculateRewards(uint256 amount, uint256 rate, uint256 duration) internal pure returns (uint256) {
        uint256 totalAnnualInterest = (amount * rate) / 100; 
        uint256 dayInterest = totalAnnualInterest / 365;  
        uint256 totalInterest = dayInterest * (duration / 1 days);  
        return totalInterest;
    }
    function getAnnualRate(uint256 term) internal pure returns (uint256) {
        if (term >= 365 days) { 
            return 20;
        } else if (term >= 180 days) { 
            return 16;
        } else if (term >= 90 days) { 
            return 12;
        } else if (term >= 30 days) { 
            return 8;
        } else if (term >= 1 days) { 
            return 5;
        } else {
            return 0; 
        }
    }
    function getStakingCurrentSupply() public view returns (uint256) {
        require(stakingToken.balanceOf(address(this)) >= totalStaked, "Invalid staking supply");
        return (stakingToken.balanceOf(address(this)) - totalStaked);
    }
}
contract ProposalManagement is IProposalManagement, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    IBEP20 public tokenContract;
    uint256 private nextProposalId = 1;
    uint256 private counter = 100;
    mapping(uint256 => bool) public validProposalIds;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    struct Proposal {
        uint256 id;
        string description;
        address eventAddress;
        uint256 amount;
        uint256 createdAt;
        uint256 endAt;
        int yes;
        int no;
        bool voteCounted;
        uint256 totalVotingPower;
        mapping(address => bool) voters;
        address[] voterAddresses;  
        bool approve;
    }
    mapping(uint256 => Proposal) private proposals;
    mapping(address => bool) public excludedFromVoting;
    address[] public excludedAddresses;
    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, bool vote, address voter, uint256 weight);
    event ProposalExecuted(uint256 proposalId, bool result);
    event ProposalAdded(uint256 indexed id);
    event ProposalRemoved(uint256 indexed id);
    constructor(address _tokenContractAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(ADMIN_ROLE, msg.sender);
        tokenContract = IBEP20(_tokenContractAddress);
        excludeAddressFromVoting(_tokenContractAddress);
        excludeAddressFromVoting(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        excludeAddressFromVoting(0x75DD50C7311b75f552dFC2cAb99039cda3e730Ed); 
    }
    function createProposal(string memory description, address eventAddress, uint256 amount, uint256 votingPeriod) external onlyRole(ADMIN_ROLE) {
        require(eventAddress != address(0), "Invalid address");
        require(amount > 0, "Amount must be greater than zero");
        uint256 proposalId = nextProposalId++;
        require(!validProposalIds[proposalId], "Proposal ID already exists");
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.description = description;
        newProposal.eventAddress = eventAddress;
        newProposal.amount = amount;
        newProposal.createdAt = block.timestamp;
        newProposal.endAt = block.timestamp + votingPeriod;
        newProposal.voteCounted = false;
        validProposalIds[proposalId] = true;
        emit ProposalCreated(proposalId, description);
    }
    function vote(uint256 proposalId, bool support) public {
        require(block.timestamp <= proposals[proposalId].endAt, "Voting period has ended");
        require(!proposals[proposalId].voteCounted, "Proposal already executed");
        require(!hasVoted[proposalId][msg.sender], "This address already voted");
        require(validProposalIds[proposalId], "Invalid id, proposal cannot be found");
        uint256 voterBalance = tokenContract.balanceOf(msg.sender);
        require(voterBalance > 0, "You must hold tokens to vote");
        proposals[proposalId].voters[msg.sender] = support;
        proposals[proposalId].voterAddresses.push(msg.sender);
        if(support){
            proposals[proposalId].yes++;
        } else {
            proposals[proposalId].no++;
        }
        emit Voted(proposalId, support, msg.sender, voterBalance);
    }
    function countVotes(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.endAt, "Voting period must have ended");
        require(!proposal.voteCounted, "Votes have already been counted");
        require(validProposalIds[proposalId], "Invalid id, proposal cannot be found");
        uint256 yesVotes = 0;
        uint256 noVotes = 0;
        uint256 totalExcludedSupply = getExcludedSupply();
        uint256 actualVotingSupply = tokenContract.totalSupply() - totalExcludedSupply;
        uint256 votingParticipationThreshold = actualVotingSupply / 2; 
        for (uint i = 0; i < proposal.voterAddresses.length; i++) {
            address voter = proposal.voterAddresses[i];
            uint256 voterBalance = tokenContract.balanceOf(voter);
            if(proposal.voters[voter]) {
                yesVotes += voterBalance;
            } else {
                noVotes += voterBalance;
            }
        }
        proposal.totalVotingPower = yesVotes + noVotes;
        proposal.voteCounted = true;
        if(proposal.totalVotingPower < votingParticipationThreshold) {
            proposal.approve = false;
            return;
        }
        proposal.approve = yesVotes > noVotes;
        emit ProposalExecuted(proposalId, proposal.approve);
    }
    function getExcludedSupply() public view returns (uint256 totalExcluded) {
        for (uint256 i = 0; i < excludedAddresses.length; i++) {
            if (excludedFromVoting[excludedAddresses[i]]) {
                totalExcluded += tokenContract.balanceOf(excludedAddresses[i]);
            }
        }
    }
    function removeProposal(uint256 proposalId) external onlyRole(ADMIN_ROLE) {
        require(proposals[proposalId].voteCounted, "Proposal must be executed before removal.");
        require(validProposalIds[proposalId], "Proposal ID does not exist");
        delete proposals[proposalId];
        validProposalIds[proposalId] = false;
        emit ProposalRemoved(proposalId);
    }
    function excludeAddressFromVoting(address _address) public onlyRole(ADMIN_ROLE) {
        require(!excludedFromVoting[_address], "Address already excluded");
        excludedFromVoting[_address] = true;
        excludedAddresses.push(_address); 
    }
    function includeAddressInVoting(address _address) public onlyRole(ADMIN_ROLE) {
        require(excludedFromVoting[_address], "Address not excluded");
        excludedFromVoting[_address] = false;
        for (uint256 i = 0; i < excludedAddresses.length; i++) {
            if (excludedAddresses[i] == _address) {
                excludedAddresses[i] = excludedAddresses[excludedAddresses.length - 1];
                excludedAddresses.pop();
                break;
            }
        }
    }
    function isProposalApproved(uint256 proposalId) external view returns (address _eventAddress, uint256 _amount, bool _approved) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.voteCounted, "Vote has not been counted");
        _eventAddress = proposal.eventAddress;
        _amount = proposal.amount;
        _approved = proposal.approve;
        return (_eventAddress, _amount, _approved);
    }
    function getProposalSummary(uint256 proposalId) external view returns (
        string memory description,
        address eventAddress,
        uint256 amount,
        uint256 createdAt,
        uint256 endAt,
        int yes,
        int no
    ) {
        require(validProposalIds[proposalId], "Proposal ID does not exist");
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.description,
            proposal.eventAddress,
            proposal.amount,
            proposal.createdAt,
            proposal.endAt,
            proposal.yes,
            proposal.no
        );
    }
    function getAllValidProposalIds() public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < counter; i++) {
            if (validProposalIds[i]) {
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < counter; i++) {
            if (validProposalIds[i]) {
                result[index] = i;
                index++;
            }
        }
        return result;
    }
    function updateCounter(uint256 _counter) external onlyRole(ADMIN_ROLE){
        counter = _counter;
    }
}