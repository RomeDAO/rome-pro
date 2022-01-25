// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/* ========== FORGE DEPENDENDCIES ========== */
import "../../lib/ds-test/src/test.sol";
import "./utils/Vm.sol";

/* ========== INTERFACES ========== */
import "./interfaces/IERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IBond.sol";
import "./interfaces/ITreasury.sol";

/* ========== CONTRACT DEPENDENCIES ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";
import {RomeProFactory} from "../contracts/factory.sol";
import {RomeProFactoryStorage} from "../contracts/factoryStorage.sol";
import {RPSubsidyRouter} from "../contracts/subsidy.sol";
import {GenericBondingCalculator} from "../contracts/genericBondingCalculator.sol";
import "./utils/Constants.sol";


/* ========== BOND CONTRACT ========== */
contract BondUser {
    using SafeMath for uint;
    
    function approve(address _token, address _who, uint _amount) public {
        IERC20( _token ).approve(_who, _amount);
    }

    function deposit(address _bond, uint _amount, uint maxPrice, address depositor) public returns(uint) {
        uint val = IBond(_bond).deposit(_amount, maxPrice, depositor);
        return val;
    }

    function addLiquidity(address router,address tokenA, address tokenB) public {
        uint amountA = IERC20(tokenA).balanceOf(address(this));
        uint amountB = IERC20(tokenB).balanceOf(address(this));
        IERC20(tokenA).approve(router,amountA);
        IERC20(tokenB).approve(router,amountB);
        IRouter(router).addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}

/* ========== GENERIC BOND TESTER ========== */
contract BondTester is DSTest, Constants {
    using SafeMath for uint;

    Vm internal constant vm = Vm(HEVM_ADDRESS);

    /* ========== USER INPUTS ============== */
    IERC20 internal PAYOUT;
    IUniswapV2Pair internal PRINCIPLE;
    IRouter internal ROUTER;
    address internal initialOwner;

    /* ========== MOVR DEPENDENCIES ========== */
    IERC20 internal WMOVR = IERC20(0x98878B06940aE243284CA214f92Bb71a2b032B8A);

    AggregatorV3Interface internal FEED = AggregatorV3Interface(0x3f8BFbDc1e79777511c00Ad8591cef888C2113C1);

    /* ========== TESTING STATE ========== */

    RomeProFactory internal factory;

    RomeProFactoryStorage internal factoryStorage;

    RPSubsidyRouter internal subsidy;
    
    GenericBondingCalculator internal calculator;

    uint movrPrice;

    address internal BOND;

    address internal TREASURY;

    uint numberUsers = 5;

    BondUser[] internal user;

    function setUpFactory() public virtual {

        //1. Deploy Factory Storage and subsidy and calculator
        factoryStorage = new RomeProFactoryStorage();

        subsidy = new RPSubsidyRouter();

        calculator = new GenericBondingCalculator();

        //2. Deploy Factory
        factory = new RomeProFactory(
            address(1), // Rome Dao Treasury
            address(factoryStorage),
            address(subsidy),
            address(this) // Rome Dao Access control
        );

        factoryStorage.setFactoryAddress(address(factory));


        movrPrice = uint(FEED.latestAnswer()); // Store Movr price in 8 decimals.
        emit log_named_uint("<MOVR Price USD> ==", movrPrice.div(1e8));

    }

    /* ========== HELPERS ========== */

    function bondPriceInUSD(uint256 bondPrice) public view returns ( uint price_ ) {
       price_ = bondPrice
                .mul( calculator.valuationInUSD(address(PRINCIPLE), address(WMOVR), address(FEED)) )
                .div(1e7);
    }

    function setBalance(address account, uint256 amount, address token, uint256 slot) public {
        vm.store(
            token,
            keccak256(abi.encode(account, slot)),
            bytes32(amount)
        );
    }


}