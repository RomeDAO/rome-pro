// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/* ========== INTERFACES ========== */
import "./interfaces/IERC20.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IBond.sol";
import "./interfaces/ITreasury.sol";

/* ========== CONTRACT DEPENDENCIES ========== */
import "@openzeppelin/contracts/math/SafeMath.sol";
import {BondUser, BondTester} from "./BOND_TESTER.t.sol";
import "./utils/Constants.sol";


contract HndMovrTest is BondTester {
    using SafeMath for uint;

    function setUp() public virtual {

        super.setUpFactory();

        /* ========== USER INPUTS ========= */
        PAYOUT = IERC20(Constants.HND_MOVR_PAYOUT); // HND token
        PRINCIPLE = IUniswapV2Pair(Constants.HND_MOVR_PRINCIPLE); // HND/MOVR liquidity
        ROUTER = IRouter(Constants.HND_MOVR_ROUTER);
        initialOwner = (Constants.HND_MULTISIG); // HND Multisig

        emit log("|==================== USER INPUTS ====================|");
        emit log_named_address("Payout Token =", address(PAYOUT));
        emit log_named_address("Principle Token =", address(PRINCIPLE));
        emit log_named_address("Router", address(ROUTER));
        emit log("|=====================================================|");


        // create bond
        uint[] memory _tierCeilings = new uint[](1);
        _tierCeilings[0] = 1000000*1e18;
        uint[] memory _fees = new uint[](1);
        _fees[0] = 33300; //change to 33,300/1,000,000

        (TREASURY, BOND) = factory.createBondAndTreasury(
            address(PAYOUT),
            address(PRINCIPLE),
            initialOwner,
            _tierCeilings,
            _fees
        );

        setBalance(TREASURY, 100000 * 1e18, address(PAYOUT), 2);

        // set up users
        for (uint i = 0; i < numberUsers; i++) {
            user.push( new BondUser() );
            user[i].approve(address(PRINCIPLE), address(BOND), type(uint256).max);
        }
        
    }

    function testDeployment() public {
        //1. set terms
        emit log("|==================== BOND TERMS ====================|");
        uint bcv = 6000;
        emit log_named_uint("<|BCV|> == ", bcv);
        uint vestingTerm = 32000;
        emit log_named_uint("<|Vesting Term in blocks|>", vestingTerm);
        uint minPrice = 1;
        emit log_named_uint("<|Min Price|> ==", minPrice);
        uint maxPayout = 5;
        emit log_named_uint("<|Max Payout|> ==", maxPayout);
        uint initialDebt = 123106712146927000000000;
        emit log_named_uint("<|Initial Debt|> ==", initialDebt);

        vm.startPrank(initialOwner);
        IBond(BOND).setBondTerms(IBond.PARAMETER(0),vestingTerm);
        IBond(BOND).initializeBond(
            bcv,
            vestingTerm,
            minPrice,
            maxPayout,
            100000000000000000000000000,
            initialDebt
        );
        ITreasury(TREASURY).toggleBondContract(BOND);
        vm.stopPrank();

        //2. Prints HND Price       
        (uint reserve0, uint reserve1,) = PRINCIPLE.getReserves();
        uint tokenPrice = reserve1.mul(movrPrice).div(reserve0);
        emit log_named_uint("<|HND Price USD (2)|> ==", tokenPrice.div(1e6));

        emit log_named_uint("<| Valuation Per Principle Token MOVR (6) |>", calculator.valuation(address(PRINCIPLE),address(WMOVR)).div(1e12));
        emit log_named_uint("<| Valuation Per Principle Token HND  (6) |>", calculator.valuation(address(PRINCIPLE),address(PAYOUT)).div(1e12));
        emit log_named_uint("<| Valuation Per Principle Token USD (6) |>", calculator.valuationInUSD(address(PRINCIPLE),address(WMOVR),address(FEED)).div(1e12));
        emit log("|===================================================|");

        //3. Users Bond
        for (uint i = 0; i < numberUsers; i++) {
            emit log_named_uint("deposit number",i+1);
            uint _bondPrice = IBond(BOND).bondPrice();
            emit log_named_uint("bond price (7)", _bondPrice);

            uint _trueBondPrice = IBond(BOND).trueBondPrice();
            emit log_named_uint("true bond price (7)", _trueBondPrice);
            emit log_named_uint("true bond price in USD (2)", bondPriceInUSD(_trueBondPrice).div(1e16));
            address addr = address(user[i]);

            // //4. mint token and Movr for LP
            setBalance(addr,10*1e18,address(WMOVR),3);
            setBalance(addr,10*1e18,address(PAYOUT),2);     

            //5. add liquidity
            uint balBefore = PAYOUT.balanceOf(addr);
            user[i].addLiquidity(address(ROUTER),address(PAYOUT),address(WMOVR));
            uint deposited = 2*(balBefore.sub(PAYOUT.balanceOf(addr)));
            emit log_named_uint("LP added in PAYOUT (4) ==", deposited.div(1e14));

            //6. purchase bonds
            uint payout = user[i].deposit(address(BOND),PRINCIPLE.balanceOf(addr), 200000*1e11, addr);
            emit log_named_uint("Payout in HND (4) ==",payout.div(1e14));

            // //7. Print Payout in USD
            uint fee = payout.mul( IBond(BOND).currentRomeFee() ).div( 1e6 );
            payout = payout.sub(fee);
            emit log_named_uint("True Payout in HND (4) ==",payout.div(1e14));
            emit log("==============================");
        }
    }
}