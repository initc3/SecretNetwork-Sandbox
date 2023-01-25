use cosmwasm_std::Binary;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum Msg {
    Nop {},
    Store1 {
        message: String,
    },
    Store2 {
        message: String,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    Store1Q {
    },
    Store2Q {
    },
    WasmSmart {
        contract_addr: String,
        code_hash: String,
        msg: Binary,
    },
    WasmContractInfo {
        contract_addr: String,
    },
    GetTxId {}
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum PacketMsg {
    Test {},
    Message { value: String },
}
