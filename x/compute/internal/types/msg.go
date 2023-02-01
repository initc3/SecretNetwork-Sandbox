package types

import (
	sdk "github.com/cosmos/cosmos-sdk/types"
	sdkerrors "github.com/cosmos/cosmos-sdk/types/errors"
)

func (msg MsgStartSnapshot) Route() string {
	return RouterKey
}

func (msg MsgStartSnapshot) Type() string {
	return "snapshot"
}

func (msg MsgStartSnapshot) ValidateBasic() error {
	// if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
	// 	return err
	// }
	return nil
}

func (msg MsgStartSnapshot) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgClearSnapshot) Route() string {
	return RouterKey
}

func (msg MsgClearSnapshot) Type() string {
	return "snapshot_clear"
}

func (msg MsgClearSnapshot) ValidateBasic() error {
	// if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
	// 	return err
	// }
	return nil
}

func (msg MsgClearSnapshot) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgSimulateTx) Route() string {
	return RouterKey
}

func (msg MsgSimulateTx) Type() string {
	return "simulatetx"
}

func (msg MsgSimulateTx) ValidateBasic() error {
	// if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
	// 	return err
	// }
	return nil
}

func (msg MsgSimulateTx) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}
func (msg MsgStoreCode) Route() string {
	return RouterKey
}

func (msg MsgStoreCode) Type() string {
	return "store-code"
}

func (msg MsgStoreCode) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}

	if err := validateWasmCode(msg.WASMByteCode); err != nil {
		return sdkerrors.Wrapf(sdkerrors.ErrInvalidRequest, "code bytes %s", err.Error())
	}

	if err := validateSourceURL(msg.Source); err != nil {
		return sdkerrors.Wrapf(sdkerrors.ErrInvalidRequest, "source %s", err.Error())
	}

	if err := validateBuilder(msg.Builder); err != nil {
		return sdkerrors.Wrapf(sdkerrors.ErrInvalidRequest, "builder %s", err.Error())
	}

	return nil
}

func (msg MsgStoreCode) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

func (msg MsgStoreCode) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgInstantiateContract) Route() string {
	return RouterKey
}

func (msg MsgInstantiateContract) Type() string {
	return "instantiate"
}

func (msg MsgInstantiateContract) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}

	if msg.CodeID == 0 {
		return sdkerrors.Wrap(sdkerrors.ErrInvalidRequest, "code_id is required")
	}

	if err := validateLabel(msg.Label); err != nil {
		return err
	}

	if !msg.InitFunds.IsValid() {
		return sdkerrors.ErrInvalidCoins
	}

	return nil
}

func (msg MsgInstantiateContract) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

func (msg MsgInstantiateContract) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}

func (msg MsgExecuteContract) Route() string {
	return RouterKey
}

func (msg MsgExecuteContract) Type() string {
	return "execute"
}

func (msg MsgExecuteContract) ValidateBasic() error {
	if err := sdk.VerifyAddressFormat(msg.Sender); err != nil {
		return err
	}
	if err := sdk.VerifyAddressFormat(msg.Contract); err != nil {
		return err
	}

	if !msg.SentFunds.IsValid() {
		return sdkerrors.Wrap(sdkerrors.ErrInvalidCoins, "sentFunds")
	}

	return nil
}

func (msg MsgExecuteContract) GetSignBytes() []byte {
	return sdk.MustSortJSON(ModuleCdc.MustMarshalJSON(&msg))
}

func (msg MsgExecuteContract) GetSigners() []sdk.AccAddress {
	return []sdk.AccAddress{msg.Sender}
}
