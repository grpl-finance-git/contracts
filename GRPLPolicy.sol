// SPDX-License-Identifier: MIT

/*     
    Golden Raito Per Liquidity
    
    
    Forked from Ampleforth: https://github.com/ampleforth/uFragments (Credits to Ampleforth team for implementation of rebasing on the ethereum network)
    
    GRPL 1.0 license
    
    GRPLPolicy.sol - GRPL Orchestrator Policy
  
*/

pragma solidity ^0.6.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

/**
 * @title Various utilities useful for uint256.
 */
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

interface IGRPL {
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
}

interface IGRPLPool {
    function afterRebase() external;
}

interface IGRPLOracle {
    function getFiboPrice() external view returns (uint256, bool);
    function getMarketPrice() external view returns (uint256, bool);
    function getFiboRate() external view returns(bool);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipRenounced(address indexed previousOwner);
  
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

/**
 * @title GRPL Supply Policy
 * @dev This is the extended orchestrator version of the GRPL Ideal Gold Pegged DeFi protocol aka Golden Raito Per Liquidity(GRPL).
 *      GRPL operates symmetrically on expansion and contraction. It will both split and
 *      combine coins to maintain a stable gold unit price against gold using Golden raito.
 *
 *      This component regulates the token supply of the GRPL ERC20 token in response to
 *      market oracles and gold price and golden raito.
 */
contract GRPLPolicy is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        uint256 grplPrice,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    IGRPL public grpl;

    // Grpl oracle provides the fibo price and market price.
    IGRPLOracle public grplOracle;
    
    IGRPLPool public grplPool;

    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    // DECIMALS Fixed point number.
    uint256 public deviationThreshold;

    // The rebase lag parameter, used to dampen the applied supply adjustment by 1 / rebaseLag
    // Check setRebaseLag comments for more details.
    // Natural number, no decimal places.
    uint256 public rebaseLag;

    // More than this much time must pass between rebase operations.
    uint256 public minRebaseTimeIntervalSec;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 10**6 * 10**DECIMALS;
    constructor() public {
        deviationThreshold = 5 * 10 ** (DECIMALS-2);

        rebaseLag = 10;
        minRebaseTimeIntervalSec = 12 hours;
        lastRebaseTimestampSec = 0;
        epoch = 0;
    }

    /**
     * @notice Returns true if at least minRebaseTimeIntervalSec seconds have passed since last rebase.
     *
     */
     
    function canRebase() public view returns (bool) {
        return (lastRebaseTimestampSec.add(minRebaseTimeIntervalSec) < now);
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     */     
    function rebase() external {
        require(canRebase(), "grpl Error: Insufficient time has passed since last rebase.");
        require(tx.origin == msg.sender);
        lastRebaseTimestampSec = now;
        epoch = epoch.add(1);
        
        (uint256 curFiboPrice, uint256 marketPrice, int256 supplyDelta) = getRebaseValues();
        grpl.rebase(epoch, supplyDelta);
        emit LogRebase(epoch, marketPrice, curFiboPrice, supplyDelta, now);
        grplPool.afterRebase();
    }
    
    /**
     * @notice Calculates the supplyDelta and returns the current set of values for the rebase
     */   
    function getRebaseValues() internal 
        view
        returns (uint256, uint256, int256) 
    {
        uint256 curFiboPrice;
        bool fiboValid;
        (curFiboPrice, fiboValid) = grplOracle.getFiboPrice();

        require(fiboValid);
        
        uint256 marketPrice;
        bool marketValid;
        (marketPrice, marketValid) = grplOracle.getMarketPrice();
        
        require(marketValid);
        
        bool fiboRate;
        fiboRate = grplOracle.getFiboRate();

        int256 supplyDelta = computeSupplyDelta(marketPrice, curFiboPrice, fiboRate);

        // if (supplyDelta > 0 && grpl.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
        //     supplyDelta = (MAX_SUPPLY.sub(grpl.totalSupply())).toInt256Safe();
        // }

       return (curFiboPrice, marketPrice, supplyDelta);
    }


    /**
     * @return Computes the total supply adjustment in response to the market price
     *         and the current fibo price. 
     */
    function computeSupplyDelta(uint256 _marketPrice, uint256 _curFiboPrice, bool fiboRate)
        internal
        view
        returns (int256)
    {
        //(current price – base target price in usd) * total supply / (base target price in usd * lag factor)
        int256 curFiboPrice = _curFiboPrice.toInt256Safe();
        int256 marketPrice = _marketPrice.toInt256Safe();
        int256 currSupply = grpl.totalSupply().toInt256Safe();
        
        if(fiboRate){
            if(marketPrice < curFiboPrice){
                int256 a = 0;
                return a.sub(marketPrice.mul(currSupply).div(curFiboPrice));
            }
            else if(marketPrice > curFiboPrice){
                return marketPrice.mul(currSupply).div(curFiboPrice);
            }
        }
        else{
            return (currSupply.mul(marketPrice.sub(curFiboPrice)).div(curFiboPrice)).div(rebaseLag.toInt256Safe());
        }
    }
    /**
     * @notice Sets the rebase lag parameter.
     * @param rebaseLag_ The new rebase lag parameter.
     */
    function setRebaseLag(uint256 rebaseLag_)
        external
        onlyOwner
    {
        require(rebaseLag_ > 0);
        rebaseLag = rebaseLag_;
    }


    /**
     * @notice Sets the parameter which control the timing and frequency of
     *         rebase operations the minimum time period that must elapse between rebase cycles.
     * @param minRebaseTimeIntervalSec_ More than this much time must pass between rebase
     *        operations, in seconds.
     */
    function setRebaseTimingParameter(uint256 minRebaseTimeIntervalSec_)
        external
        onlyOwner
    {
        minRebaseTimeIntervalSec = minRebaseTimeIntervalSec_;
    }

    /**
     * @param rate The current market price
     * @param targetRate The current gold price
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate, uint256 targetRate)
        internal
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold)
            .div(10 ** DECIMALS);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }
    
    
    /**
     * @notice Sets the reference to the grpl token governed.
     *         Can only be called once during initialization.
     * 
     * @param grpl_ The address of the grpl ERC20 token.
     */
    function setGRPL(IGRPL grpl_)
        external
        onlyOwner
    {
        require(grpl == IGRPL(0)); 
        grpl = grpl_;    
    }
    
    
    function setGRPLPool(IGRPLPool _grplPool)
        external
        onlyOwner
    { 
        grplPool = _grplPool;
    }

    /**
     * @notice Sets the reference to the grpl $grpl oracle.
     * @param _grplOracle The address of the grpl oracle contract.
     */
    function setGRPLOracle(IGRPLOracle _grplOracle)
        external
        onlyOwner
    {
        grplOracle = _grplOracle;
    }
    
}