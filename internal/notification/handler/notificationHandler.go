package handler

import (
	"net/http"

	"amazonpilot/internal/notification/internal/logic"
	"amazonpilot/internal/notification/internal/svc"
	"amazonpilot/internal/notification/internal/types"
	"github.com/zeromicro/go-zero/rest/httpx"
)

func NotificationHandler(svcCtx *svc.ServiceContext) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req types.Request
		if err := httpx.Parse(r, &req); err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
			return
		}

		l := logic.NewNotificationLogic(r.Context(), svcCtx)
		resp, err := l.Notification(&req)
		if err != nil {
			httpx.ErrorCtx(r.Context(), w, err)
		} else {
			httpx.OkJsonCtx(r.Context(), w, resp)
		}
	}
}
