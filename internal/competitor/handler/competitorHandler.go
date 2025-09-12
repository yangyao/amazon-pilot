package handler

import (
	"net/http"

	"amazonpilot/internal/competitor/internal/logic"
	"amazonpilot/internal/competitor/internal/svc"
	"amazonpilot/internal/competitor/internal/types"
	"github.com/zeromicro/go-zero/rest/httpx"
)

func CompetitorHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.Request
		if err := httpx.Parse(r, &req); err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
			return
		}

		l := logic.NewCompetitorLogic(r.Context(), svcCtx)
		resp, err := l.Competitor(&req)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
