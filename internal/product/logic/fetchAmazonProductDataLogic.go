package logic

import (
	"context"

	"amazonpilot/internal/product/svc"
	"amazonpilot/internal/product/types"

	"github.com/zeromicro/go-zero/core/logx"
)

type FetchAmazonProductDataLogic struct {
	logx.Logger
	ctx    context.Context
	svcCtx *svc.ServiceContext
}

func NewFetchAmazonProductDataLogic(ctx context.Context, svcCtx *svc.ServiceContext) *FetchAmazonProductDataLogic {
	return &FetchAmazonProductDataLogic{
		Logger: logx.WithContext(ctx),
		ctx:    ctx,
		svcCtx: svcCtx,
	}
}

func (l *FetchAmazonProductDataLogic) FetchAmazonProductData(req *types.FetchProductDataRequest) (resp *types.FetchProductDataResponse, err error) {
	// todo: add your logic here and delete this line

	return
}
