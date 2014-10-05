(ns application.core
  (:require [compojure.core :refer [GET defroutes]]
            [compojure.route :as route]
            [compojure.handler :as handler]
            [org.httpkit.server :as server]
            [ring.middleware.json :as middleware]
            [ring.util.response :as ring])
  (:gen-class))

(defn dummy-function [x]
  (inc x))

(defroutes app-routes
  (GET  "/" [] (ring/resource-response "index.html" {:root "public"}))
  (route/resources "/")
  (route/not-found "Keep movin', there ain't nothin' to see here."))

(def app (handler/site app-routes))

(defn -main []
  (server/run-server app {:port 8080}))
