use cosmwasm_std::{to_binary, Binary, StdError, entry_point, Deps, DepsMut, Env, MessageInfo, StdResult, Response};
use crate::msg::{HandleMsg, QueryMsg};
use crate::state::*;

#[entry_point]
pub fn instantiate(deps: DepsMut, env: Env, info: MessageInfo, msg: HandleMsg) -> StdResult<Response> {
    return handle(deps, env, info, msg);
}

#[entry_point]
pub fn execute(deps: DepsMut, env: Env, info: MessageInfo, msg: HandleMsg) -> StdResult<Response> {
    return handle(deps, env, info, msg);
}

pub fn handle(
    deps: DepsMut,
    _env: Env,
    info: MessageInfo,
    msg: HandleMsg,
) -> StdResult<Response> {
    match msg {
        HandleMsg::Swap {
            token_type,
            offer_amt,
            expected_return_amt,
            receiver,
        } => {
            match token_type.as_str() {
                "token_a" => {
                    let sender = info.sender;
                    let amt_a = offer_amt;
                    let expected_amt_b = expected_return_amt;

                    let mut balance_a = read_balance_a(deps.storage, &sender);
                    if balance_a.lt(&amt_a) {
                        return Err(StdError::generic_err(
                            "Not enough balance",
                        ));
                    }

                    let mut pool_a = read_pool_a(deps.storage)?;
                    let mut pool_b = read_pool_b(deps.storage)?;

                    let total_pool = pool_a * pool_b;
                    let actual_amt_b = pool_b - (total_pool / (pool_a + amt_a));

                    if actual_amt_b.lt(&expected_amt_b) {
                        return Err(StdError::generic_err(
                            "Operation fell short of expected_return",
                        ));
                    }

                    pool_a += amt_a;
                    pool_b -= actual_amt_b;
                    store_pool_a(deps.storage, pool_a)?;
                    store_pool_b(deps.storage, pool_b)?;

                    balance_a -= amt_a;
                    store_balance_a(deps.storage, &sender, balance_a)?;

                    let mut balance_b = read_balance_b(deps.storage, &receiver);
                    balance_b += actual_amt_b;
                    store_balance_b(deps.storage, &receiver, balance_b)?;
                },
                "token_b" => {let sender = info.sender;
                    let amt_b = offer_amt;
                    let expected_amt_a = expected_return_amt;

                    let mut balance_b = read_balance_b(deps.storage, &sender);
                    if balance_b.lt(&amt_b) {
                        return Err(StdError::generic_err(
                            "Not enough balance",
                        ));
                    }

                    let mut pool_a = read_pool_a(deps.storage)?;
                    let mut pool_b = read_pool_b(deps.storage)?;

                    let total_pool = pool_a * pool_b;
                    let actual_amt_a = pool_a - (total_pool / (pool_b + amt_b));

                    if actual_amt_a.lt(&expected_amt_a) {
                        return Err(StdError::generic_err(
                            "Operation fell short of expected_return",
                        ));
                    }

                    pool_a -= actual_amt_a;
                    pool_b += amt_b;
                    store_pool_a(deps.storage, pool_a)?;
                    store_pool_b(deps.storage, pool_b)?;

                    balance_b -= amt_b;
                    store_balance_b(deps.storage, &sender, balance_b)?;

                    let mut balance_a = read_balance_a(deps.storage, &receiver);
                    balance_a += actual_amt_a;
                    store_balance_a(deps.storage, &receiver, balance_a)?;
                },
                _ => {}
            }


        },
        HandleMsg::Init {
            pool_a,
            pool_b
        } => {
            store_pool_a(deps.storage, pool_a.into())?;
            store_pool_b(deps.storage, pool_b.into())?;
        },
        HandleMsg::InitBalance {
            token_type,
            user,
            balance,
        } => {
            match token_type.as_str() {
                "token_a" => {
                    store_balance_a(deps.storage, &user, balance)?;
                },
                "token_b" => {
                    store_balance_b(deps.storage, &user, balance)?;
                },
                _ => {}
            }
        }
    }
    return Ok(
        Response::new()
    );
}

#[entry_point]
pub fn query(deps: Deps, _env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::PoolA {} => Ok(to_binary(&read_pool_a(deps.storage)?)?),
        QueryMsg::PoolB {} => Ok(to_binary(&read_pool_b(deps.storage)?)?),
        QueryMsg::Balance {
            token_type,
            user,
        } => {
            let res = match token_type.as_str() {
                "token_a" => {
                    read_balance_a(deps.storage, &user)
                },
                "token_b" => {
                    read_balance_b(deps.storage, &user)
                },
                _ => {
                    return Err(StdError::generic_err(
                        "Invalid token type",
                    ));
                }
            };
            Ok(to_binary(&res)?)
        },
    }
}