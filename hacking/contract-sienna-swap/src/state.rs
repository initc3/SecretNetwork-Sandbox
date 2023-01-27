use cosmwasm_std::{StdResult, Storage};
use cosmwasm_storage::{ReadonlySingleton, Singleton};

static POOL_A: &[u8] = b"POOL_A";

pub fn store_pool_a(storage: &mut dyn Storage, pool_a: u64) -> StdResult<()> {
    Singleton::new(storage, POOL_A).save(&pool_a)
}

pub fn read_pool_a(storage: &dyn Storage) -> StdResult<u64> {
    ReadonlySingleton::new(storage, POOL_A).load()
}

static POOL_B: &[u8] = b"POOL_B";

pub fn store_pool_b(storage: &mut dyn Storage, pool_b: u64) -> StdResult<()> {
    Singleton::new(storage, POOL_B).save(&pool_b)
}

pub fn read_pool_b(storage: &dyn Storage) -> StdResult<u64> {
    ReadonlySingleton::new(storage, POOL_B).load()
}