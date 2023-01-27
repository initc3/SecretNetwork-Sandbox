use cosmwasm_std::{to_binary, Binary, StdError, entry_point, Deps, DepsMut, Env, MessageInfo, StdResult, Response};
use crate::msg::{HandleMsg, QueryMsg};
use crate::state::{read_pool_a, read_pool_b, store_pool_a, store_pool_b};

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
    _info: MessageInfo,
    msg: HandleMsg,
) -> StdResult<Response> {
    match msg {
        HandleMsg::Swap {
            amt_a,
            expected_amt_b,
            recipient,
        } => {
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
        },
        HandleMsg::Init {
            pool_a,
            pool_b
        } => {
            store_pool_a(deps.storage, pool_a.into())?;
            store_pool_b(deps.storage, pool_b.into())?;
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
    }
}