package handler

import (
	"net/http"

	"amazonpilot/internal/product/internal/logic"
	"amazonpilot/internal/product/internal/svc"
	"amazonpilot/internal/product/internal/types"
	"github.com/zeromicro/go-zero/rest/httpx"
)

func ProductHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.Request
		if err := httpx.Parse(r, &req); err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
			return
		}

		l := logic.NewProductLogic(r.Context(), svcCtx)
		resp, err := l.Product(&req)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
