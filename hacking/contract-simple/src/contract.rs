use cosmwasm_std::{
    entry_point, to_binary, to_vec, Binary, ContractInfoResponse, ContractResult, Deps,
    DepsMut, Empty, Env, MessageInfo, QueryRequest, Response, StdError, StdResult,
    WasmQuery,
};

use crate::msg::{Msg, QueryMsg};
use crate::state::{
    store1, store1_read,
    store2, store2_read
};

#[entry_point]
pub fn instantiate(deps: DepsMut, env: Env, info: MessageInfo, msg: Msg) -> StdResult<Response> {
    store1(deps.storage).save(&"init val 1".to_string())?;
    store1(deps.storage).save(&"init val 2".to_string())?;
    return handle_msg(deps, env, info, msg);
}

#[entry_point]
pub fn execute(deps: DepsMut, env: Env, info: MessageInfo, msg: Msg) -> StdResult<Response> {
    return handle_msg(deps, env, info, msg);
}

fn handle_msg(deps: DepsMut, _env: Env, _info: MessageInfo, msg: Msg) -> StdResult<Response> {
    match msg {
        Msg::Nop {} => {
            return Ok(Response::new().set_data(vec![137, 137].as_slice()));
        },
        Msg::Store1 { message } => {
            store1(deps.storage).save(&message)?;
            return Ok(
                Response::new()
            );
        },
        Msg::Store2 { message } => {
            store2(deps.storage).save(&message)?;
            return Ok(
                Response::new()
            );
        },
    }
}

#[entry_point]
pub fn query(deps: Deps, env: Env, msg: QueryMsg) -> StdResult<Binary> {
    match msg {
        QueryMsg::Store1Q {} => Ok(to_binary(&store1_read(deps.storage).load()?)?),
        QueryMsg::Store2Q {} => Ok(to_binary(&store2_read(deps.storage).load()?)?),
        QueryMsg::WasmSmart {
            contract_addr,
            code_hash,
            msg,
        } => {
            let result = &deps
                .querier
                .raw_query(&to_vec(&QueryRequest::Wasm::<Empty>(WasmQuery::Smart {
                    contract_addr,
                    code_hash,
                    msg,
                }))?)
                .unwrap();

            match result {
                ContractResult::Ok(ok) => Ok(Binary(ok.0.to_vec())),
                ContractResult::Err(err) => Err(StdError::generic_err(err)),
            }
        }
        QueryMsg::WasmContractInfo { contract_addr } => {
            return Ok(to_binary(&deps.querier.query::<ContractInfoResponse>(
                &QueryRequest::Wasm(WasmQuery::ContractInfo { contract_addr }),
            )?)?);
        }
        QueryMsg::GetTxId {} => match env.transaction {
            None => Err(StdError::generic_err("Transaction info wasn't set")),
            Some(t) => return Ok(to_binary(&t.index)?),
        }
    }
}
