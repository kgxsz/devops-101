(defproject application "0.1.0-SNAPSHOT"
  :description "a dummy application"
  :dependencies [[org.clojure/clojure "1.6.0"]
                 [compojure "1.1.9"]
                 [ring "1.3.1"]
                 [ring/ring-json "0.2.0"]
                 [http-kit "2.1.19"]]
  :main ^:skip-aot application.core
  :target-path "target/%s"
  :profiles {:uberjar {:aot :all}})
