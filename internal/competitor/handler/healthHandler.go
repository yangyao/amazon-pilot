package handler

import (
	"net/http"

	"github.com/zeromicro/go-zero/rest/httpx"
	"amazonpilot/internal/competitor/logic"
	"amazonpilot/internal/competitor/svc"
)

func healthHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		l := logic.NewHealthLogic(r.Context(), svcCtx)
		resp, err := l.Health()
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
