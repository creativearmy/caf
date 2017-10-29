package com.creativearmy.template;

import java.io.Serializable;

/**
 * Created by CureChen on 2016/3/20 0020.
 */
public class i072Goodat implements Serializable{

        private String gaKey;
        private String gaName;
        private Boolean gaFlag = false;

        public String getGaKey() {
            return gaKey;
        }

        public void setGaKey(String gaKey) {
            this.gaKey = gaKey;
        }

        public String getGaName() {
            return gaName;
        }

        public void setGaName(String gaName) {
            this.gaName = gaName;
        }

        public Boolean getGaFlag() {
            return gaFlag;
        }

        public void setGaFlag(Boolean gaFlag) {
            this.gaFlag = gaFlag;
        }
}
