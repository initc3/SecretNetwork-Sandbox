package keeper

import (
	"context"
	"fmt"

	sdk "github.com/cosmos/cosmos-sdk/types"

	"github.com/scrtlabs/SecretNetwork/x/compute/internal/types"
)

var _ types.MsgServer = msgServer{}

type msgServer struct {
	keeper Keeper
}

func NewMsgServerImpl(k Keeper) types.MsgServer {
	return &msgServer{keeper: k}
}

func (m msgServer) StartSnapshot(goCtx context.Context, msg *types.MsgStartSnapshot) (*types.MsgResponse, error) {
	fmt.Printf("nerla x/compute/internal/keeper/msg_server.go StartSnapshot snapshot_name: %s\n", msg.SnapshotName)
	ChangeSnapshot(string(msg.SnapshotName))
	return &types.MsgResponse{
		Result: true,
	}, nil
}

func (m msgServer) ClearSnapshot(goCtx context.Context, msg *types.MsgClearSnapshot) (*types.MsgResponse, error) {
	fmt.Printf("nerla x/compute/internal/keeper/msg_server.go ClearSnapshot snapshot_name: %s\n", msg.SnapshotName)
	m.keeper.ClearSnapshot(string(msg.SnapshotName))
	return &types.MsgResponse{
		Result: true,
	}, nil
}

func (m msgServer) SimulateTx(goCtx context.Context, msg *types.MsgSimulateTx) (*types.MsgResponse, error) {
	fmt.Printf("nerla SHOULD NOT BE REACHED x/compute/internal/keeper/msg_server.go SimulateTx tx: %x\n", msg.Tx)
	// ctx := sdk.UnwrapSDKContext(goCtx)
	return &types.MsgResponse{
		Result: false,
	}, nil
}

func (m msgServer) StoreCode(goCtx context.Context, msg *types.MsgStoreCode) (*types.MsgStoreCodeResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	ctx.EventManager().EmitEvent(sdk.NewEvent(
		sdk.EventTypeMessage,
		sdk.NewAttribute(sdk.AttributeKeyModule, types.ModuleName),
		sdk.NewAttribute(sdk.AttributeKeySender, msg.Sender.String()),
		sdk.NewAttribute(types.AttributeKeySigner, msg.Sender.String()),
	))

	codeID, err := m.keeper.Create(ctx, msg.Sender, msg.WASMByteCode, msg.Source, msg.Builder)
	if err != nil {
		return nil, err
	}

	ctx.EventManager().EmitEvents(sdk.Events{
		sdk.NewEvent(
			sdk.EventTypeMessage,
			sdk.NewAttribute(types.AttributeKeyCodeID, fmt.Sprintf("%d", codeID)),
		),
	})

	return &types.MsgStoreCodeResponse{
		CodeID: codeID,
	}, nil
}

func (m msgServer) InstantiateContract(goCtx context.Context, msg *types.MsgInstantiateContract) (*types.MsgInstantiateContractResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	contractAddr, data, err := m.keeper.Instantiate(ctx, msg.CodeID, msg.Sender, msg.InitMsg, msg.Label, msg.InitFunds, msg.CallbackSig)
	if err != nil {
		return nil, err
	}

	ctx.EventManager().EmitEvent(sdk.NewEvent(
		sdk.EventTypeMessage,
		sdk.NewAttribute(sdk.AttributeKeyModule, types.ModuleName),
		sdk.NewAttribute(sdk.AttributeKeySender, msg.Sender.String()),
		sdk.NewAttribute(types.AttributeKeyContractAddr, contractAddr.String()),
	))

	// note: even if contractAddr == nil then contractAddr.String() is ok
	// \o/🤷🤷‍♂️🤷‍♀️🤦🤦‍♂️🤦‍♀️
	return &types.MsgInstantiateContractResponse{
		Address: contractAddr.String(),
		Data:    data,
	}, nil
}

func (m msgServer) ExecuteContract(goCtx context.Context, msg *types.MsgExecuteContract) (*types.MsgExecuteContractResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	ctx.EventManager().EmitEvent(sdk.NewEvent(
		sdk.EventTypeMessage,
		sdk.NewAttribute(sdk.AttributeKeyModule, types.ModuleName),
		sdk.NewAttribute(sdk.AttributeKeySender, msg.Sender.String()),
		sdk.NewAttribute(types.AttributeKeyContractAddr, msg.Contract.String()),
	))

	data, err := m.keeper.Execute(ctx, msg.Contract, msg.Sender, msg.Msg, msg.SentFunds, msg.CallbackSig)
	if err != nil {
		return nil, err
	}

	return &types.MsgExecuteContractResponse{
		Data: data.Data,
	}, nil
}
