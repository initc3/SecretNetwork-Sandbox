use cosmwasm_std::{StdResult, Storage, Addr};
use cosmwasm_storage::{ReadonlySingleton, Singleton};
use secret_toolkit::storage::Item;

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

pub const PREFIX_BALANCES_A: &[u8] = b"balances_a";
pub static BALANCES_A: Item<u64> = Item::new(PREFIX_BALANCES_A);

pub fn read_balance_a(store: &dyn Storage, account: &Addr) -> u64 {
    let balances_a = BALANCES_A.add_suffix(account.as_str().as_bytes());
    balances_a.load(store).unwrap_or_default()
}

pub fn store_balance_a(store: &mut dyn Storage, account: &Addr, amount: u64) -> StdResult<()> {
    let balances_a = BALANCES_A.add_suffix(account.as_str().as_bytes());
    balances_a.save(store, &amount)
}

pub const PREFIX_BALANCES_B: &[u8] = b"balances_b";
pub static BALANCES_B: Item<u64> = Item::new(PREFIX_BALANCES_B);

pub fn read_balance_b(store: &dyn Storage, account: &Addr) -> u64 {
    let balances_b = BALANCES_B.add_suffix(account.as_str().as_bytes());
    balances_b.load(store).unwrap_or_default()
}

pub fn store_balance_b(store: &mut dyn Storage, account: &Addr, amount: u64) -> StdResult<()> {
    let balances_b = BALANCES_B.add_suffix(account.as_str().as_bytes());
    balances_b.save(store, &amount)
}